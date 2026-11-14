import { Request, Response } from "express";
import courseService from "../services/course.service";
import courseImageService from "../services/course-image.service";

// Controller مسؤول عن استقبال طلبات الدورات.
class CourseController {
  // إنشاء دورة جديدة.
  async createCourse(req: Request, res: Response): Promise<void> {
    let uploadedImage: { url: string; publicId: string } | undefined;

    try {
      if (req.file) {
        uploadedImage = await courseImageService.upload(req.file.buffer);
      }

      const input = {
        ...req.body,
        ...(req.body.price !== undefined && {
          price: Number(req.body.price),
        }),
        ...(req.body.depositAmount !== undefined && {
          depositAmount: Number(req.body.depositAmount),
        }),
        ...(req.body.capacity !== undefined && {
          capacity: Number(req.body.capacity),
        }),
        ...(req.body.whatWillLearn !== undefined && {
          whatWillLearn: this.parseStringArray(req.body.whatWillLearn),
        }),
        ...(req.body.features !== undefined && {
          features: this.parseStringArray(req.body.features),
        }),
        ...(uploadedImage && { image: uploadedImage.url }),
      };
      const result = await courseService.createCourse(
        req.user!.userId,
        input,
      );

      res.status(201).json({
        success: true,
        message: "Course created successfully",
        data: result,
      });
    } catch (error) {
      if (uploadedImage) {
        try {
          await courseImageService.delete(uploadedImage.publicId);
        } catch (cleanupError) {
          console.error(
            "Failed to clean up uploaded course image:",
            cleanupError,
          );
        }
      }
      this.handleError(res, error);
    }
  }

  // تحويل الحقول النصية (سواء مصفوفة أو نص JSON أو نص مفصول بفواصل) إلى مصفوفة نصوص.
  private parseStringArray(value: unknown): string[] {
    if (Array.isArray(value)) {
      if (!value.every((item) => typeof item === "string")) {
        throw new Error("Course list items must be strings");
      }
      return value.map((item) => item.trim()).filter(Boolean);
    }
    if (typeof value === "string") {
      if (!value.trim()) {
        return [];
      }

      try {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) {
          return this.parseStringArray(parsed);
        }
      } catch {
        // Plain text lists remain supported for multipart clients.
      }

      if (value.trimStart().startsWith("[")) {
        throw new Error("Course list must be a valid array");
      }

      return value.split(/[\n,]+/).map((item) => item.trim()).filter(Boolean);
    }
    throw new Error("Course list must be an array or string");
  }

  // استخراج معرف الدورة والتأكد من أنه نص.
  private getCourseId(req: Request): string {
    const courseId = req.params.courseId;

    if (typeof courseId !== "string") {
      throw new Error("Invalid course ID");
    }

    return courseId;
  }
  // عرض دورات المعهد الحالي.
  async getMyCourses(req: Request, res: Response): Promise<void> {
    try {
      const result = await courseService.getMyCourses(req.user!.userId);

      res.status(200).json({
        success: true,
        message: "Courses retrieved successfully",
        data: result,
      });
    } catch (error) {
      this.handleError(res, error);
    }
  }

  // عرض دورة محددة.
  async getMyCourseById(req: Request, res: Response): Promise<void> {
    try {
      const result = await courseService.getMyCourseById(
        req.user!.userId,
        this.getCourseId(req),
      );

      res.status(200).json({
        success: true,
        message: "Course retrieved successfully",
        data: result,
      });
    } catch (error) {
      this.handleError(res, error);
    }
  }

  // تعديل دورة.
  async updateCourse(req: Request, res: Response): Promise<void> {
    try {
      const input = {
        ...req.body,
        ...(req.body.whatWillLearn !== undefined && {
          whatWillLearn: this.parseStringArray(req.body.whatWillLearn),
        }),
        ...(req.body.features !== undefined && {
          features: this.parseStringArray(req.body.features),
        }),
      };
      const result = await courseService.updateCourse(
        req.user!.userId,
        this.getCourseId(req),

        input,
      );

      res.status(200).json({
        success: true,
        message: "Course updated successfully",
        data: result,
      });
    } catch (error) {
      this.handleError(res, error);
    }
  }

  // نشر دورة.
  async publishCourse(req: Request, res: Response): Promise<void> {
    try {
      const result = await courseService.publishCourse(
        req.user!.userId,
        this.getCourseId(req),
      );

      res.status(200).json({
        success: true,
        message: "Course published successfully",
        data: result,
      });
    } catch (error) {
      this.handleError(res, error);
    }
  }

  // إغلاق التسجيل في دورة.
  async closeCourse(req: Request, res: Response): Promise<void> {
    try {
      const result = await courseService.closeCourse(
        req.user!.userId,
        this.getCourseId(req),
      );

      res.status(200).json({
        success: true,
        message: "Course closed successfully",
        data: result,
      });
    } catch (error) {
      this.handleError(res, error);
    }
  }

  // حذف دورة مسودة.
  async deleteCourse(req: Request, res: Response): Promise<void> {
    try {
      const result = await courseService.deleteCourse(
        req.user!.userId,
        this.getCourseId(req),
      );

      res.status(200).json({
        success: true,
        message: "Course deleted successfully",
        data: result,
      });
    } catch (error) {
      this.handleError(res, error);
    }
  }

  // توحيد معالجة أخطاء عمليات الدورات.
  private handleError(res: Response, error: unknown): void {
    const message =
      error instanceof Error ? error.message : "Course operation failed";

    const statusCode =
      message === "Course not found" ||
      message === "Active institute not found" ||
      message === "Institute owner not found"
        ? 404
        : 400;

    res.status(statusCode).json({
      success: false,
      message,
    });
  }
}

export default new CourseController();
