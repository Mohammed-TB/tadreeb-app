
import mongoose from "mongoose";

import Favorite from "../models/favorite.model";
import { FavoriteTargetType } from "../types/favorite.type";
import Course from "../../courses/models/course.model";
import Institute from "../../institutes/models/institute.model";



class FavoriteService {
  // التحقق من وجود الدورة أو المعهد.
  private async checkTargetExists(
    targetType: FavoriteTargetType,
    targetId: string
  ): Promise<void> {
    if (!mongoose.Types.ObjectId.isValid(targetId)) {
      throw new Error("Invalid favorite target ID");
    }

    let exists = false;

    if (targetType === FavoriteTargetType.COURSE) {
      exists = !!(await Course.exists({ _id: targetId }));
    } else if (targetType === FavoriteTargetType.INSTITUTE) {
      exists = !!(await Institute.exists({ _id: targetId }));
    } else {
      throw new Error("Invalid favorite target type");
    }

    if (!exists) {
      throw new Error("Favorite target not found");
    }
  }

  // إضافة دورة أو معهد إلى مفضلة الطالب.
  async addFavorite(
    studentId: string,
    targetType: FavoriteTargetType,
    targetId: string
  ) {
    await this.checkTargetExists(targetType, targetId);

    // upsert يمنع إنشاء سجل جديد إذا كان موجودًا مسبقًا.
    const favorite = await Favorite.findOneAndUpdate(
      {
        studentId,
        targetType,
        targetId,
      },
      {
        $setOnInsert: {
          studentId,
          targetType,
          targetId,
        },
      },
      {
        new: true,
        upsert: true,
      }
    );

    return favorite;
  }

  // إزالة دورة أو معهد من مفضلة الطالب.
  async removeFavorite(
    studentId: string,
    targetType: FavoriteTargetType,
    targetId: string
  ) {
    const favorite = await Favorite.findOneAndDelete({
      studentId,
      targetType,
      targetId,
    });

    if (!favorite) {
      throw new Error("Favorite not found");
    }

    return favorite;
  }

  // جلب المفضلة حسب النوع.
  async getFavorites(
    studentId: string,
    targetType: FavoriteTargetType
  ) {
    if (!Object.values(FavoriteTargetType).includes(targetType)) {
      throw new Error("Invalid favorite target type");
    }

    const favorites = await Favorite.find({
      studentId,
      targetType,
    }).sort({ createdAt: -1 });

    // استخراج معرفات الدورات أو المعاهد.
    const targetIds = favorites.map((favorite) => favorite.targetId);

    // جلب البيانات الفعلية حسب النوع.
    let items: unknown[] = [];

    if (targetType === FavoriteTargetType.COURSE) {
      items = await Course.find({
        _id: { $in: targetIds },
      });
    } else {
      items = await Institute.find({
        _id: { $in: targetIds },
      });
    }

    return items;
  }
}

export default new FavoriteService();
