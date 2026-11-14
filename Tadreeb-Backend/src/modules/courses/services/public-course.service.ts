import mongoose from "mongoose";
import Course from "../models/course.model";
import Institute, { InstituteStatus } from "../../institutes/models/institute.model";
import { CourseStatus } from "../types/course.types";

class PublicCourseService {
  // عرض الدورات المنشورة والمتاحة للطلاب.
  async getPublishedCourses(query: {
    search?: string;
    category?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 10));

    // لا نعرض دورات المعاهد غير النشطة.
    const activeInstitutes = await Institute.find({
      status: InstituteStatus.ACTIVE,
    }).select("_id");

    const instituteIds = activeInstitutes.map(
      (institute) => new mongoose.Types.ObjectId(institute.id),
    );

    const filter: any = {
      status: CourseStatus.PUBLISHED,
      endDate: { $gte: new Date() },
      instituteId: { $in: instituteIds },
    };

    // البحث في عنوان الدورة ووصفها.
    if (query.search?.trim()) {
      const search = query.search.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      filter.$or = [
        { title: { $regex: search, $options: "i" } },
        { description: { $regex: search, $options: "i" } },
      ];
    }

    // التصفية حسب التصنيف.
    if (query.category?.trim()) {
      filter.category = query.category.trim();
    }

    const [courses, total] = await Promise.all([
      Course.find(filter)
        .populate("instituteId", "name address logo")
        .sort({ startDate: 1 })
        .skip((page - 1) * limit)
        .limit(limit),

      Course.countDocuments(filter),
    ]);

    return {
      courses,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // عرض تفاصيل دورة منشورة واحدة.
  async getPublishedCourseById(courseId: string) {
    if (!mongoose.Types.ObjectId.isValid(courseId)) {
      throw new Error("Invalid course ID");
    }

    const course = await Course.findOne({
      _id: courseId,
      status: CourseStatus.PUBLISHED,
      endDate: { $gte: new Date() },
    }).populate("instituteId", "name address logo");

    if (!course) {
      throw new Error("Course not found");
    }

    const institute = await Institute.findOne({
      _id: course.instituteId,
      status: InstituteStatus.ACTIVE,
    });

    if (!institute) {
      throw new Error("Course not found");
    }

    return course;
  }
}

export default new PublicCourseService();