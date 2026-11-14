
import { Request, Response, NextFunction } from "express";
import favoriteService from "../services/favorite.service";
import { FavoriteTargetType } from "../types/favorite.type";



class FavoriteController {
  // إضافة عنصر للمفضلة.
  async addFavorite(
    req: Request,
    res: Response,
    next: NextFunction
  ) {
    try {
      const studentId = req.user!.userId;
      const { targetType } = req.params;
      const { targetId } = req.body;

      const favorite = await favoriteService.addFavorite(
        studentId,
        targetType as FavoriteTargetType,
        targetId
      );

      return res.status(200).json({
        success: true,
        message: "Added to favorites successfully",
        data: favorite,
      });
    } catch (error) {
      next(error);
    }
  }


  // حذف عنصر من المفضلة.
  async removeFavorite(
    req: Request,
    res: Response,
    next: NextFunction
  ) {
    try {
      const studentId = req.user!.userId;

      const { targetType, targetId } = req.params;

      // التأكد من أن القيم نصوص وليست مصفوفات.
      if (
        typeof targetType !== "string" ||
        typeof targetId !== "string"
      ) {
        return res.status(400).json({
          success: false,
          message: "Invalid favorite parameters",
        });
      }

      await favoriteService.removeFavorite(
        studentId,
        targetType as FavoriteTargetType,
        targetId
      );

      return res.status(200).json({
        success: true,
        message: "Removed from favorites successfully",
      });
    } catch (error) {
      next(error);
    }
  }

  // جلب المفضلة حسب النوع.
  async getFavorites(
    req: Request,
    res: Response,
    next: NextFunction
  ) {
    try {
      const studentId = req.user!.userId;
      const { type } = req.query;

      const favorites = await favoriteService.getFavorites(
        studentId,
        type as FavoriteTargetType
      );

      return res.status(200).json({
        success: true,
        data: favorites,
      });
    } catch (error) {
      next(error);
    }
  }
}

export default new FavoriteController();
