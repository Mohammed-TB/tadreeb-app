import { Request, Response } from "express";
import publicCourseService from "../services/public-course.service";

class PublicCourseController {
  // GET /api/courses
  async getCourses(req: Request, res: Response) {
    try {
      const result = await publicCourseService.getPublishedCourses({
        search: typeof req.query.search === "string"
          ? req.query.search
          : undefined,

        category: typeof req.query.category === "string"
          ? req.query.category
          : undefined,

        page: Number(req.query.page) || 1,
        limit: Number(req.query.limit) || 10,
      });

      return res.status(200).json({
        success: true,
        message: "Courses fetched successfully",
        data: result.courses,
        pagination: result.pagination,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error instanceof Error ? error.message : "Server error",
      });
    }
  }

  // GET /api/courses/:courseId
  async getCourseById(req: Request, res: Response) {
    try {
      const courseId = req.params.courseId;

      if (typeof courseId !== "string") {
        return res.status(400).json({
          success: false,
          message: "Invalid course ID",
        });
      }

      const course =
        await publicCourseService.getPublishedCourseById(courseId);

      return res.status(200).json({
        success: true,
        message: "Course fetched successfully",
        data: course,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Server error";

      return res.status(message === "Course not found" ? 404 : 400).json({
        success: false,
        message,
      });
    }
  }
}

export default new PublicCourseController();