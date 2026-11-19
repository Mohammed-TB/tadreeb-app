import mongoose from "mongoose";
import Course from "../models/course.model";
import Institute, { InstituteStatus } from "../../institutes/models/institute.model";
import { CourseStatus } from "../types/course.types";
import { getSaudiDayStart } from "../utils/course-date";

class PublicCourseService {
  private async getActivePublishedCourseFilter(): Promise<Record<string, any>> {
    const activeInstitutes = await Institute.find({
      status: InstituteStatus.ACTIVE,
    }).select("_id");

    return {
      status: CourseStatus.PUBLISHED,
      endDate: { $gte: getSaudiDayStart() },
      instituteId: {
        $in: activeInstitutes.map(
          (institute) => new mongoose.Types.ObjectId(institute.id),
        ),
      },
    };
  }

  async getPublishedCategories(): Promise<string[]> {
    const filter = await this.getActivePublishedCourseFilter();
    const categories = await Course.distinct("category", filter);
    return categories
      .map((category: string) => category.trim())
      .filter((category: string) => category.length > 0)
      .sort((first: string, second: string) => first.localeCompare(second));
  }

  // عرض الدورات المنشورة والمتاحة للطلاب.
  async getPublishedCourses(query: {
    search?: string;
    category?: string;
    instituteId?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 10));

    // لا نعرض دورات المعاهد غير النشطة.
    const filter = await this.getActivePublishedCourseFilter();

    if (query.instituteId) {
      filter.instituteId = {
        ...filter.instituteId,
        $eq: new mongoose.Types.ObjectId(query.instituteId),
      };
    }

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
      endDate: { $gte: getSaudiDayStart() },
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