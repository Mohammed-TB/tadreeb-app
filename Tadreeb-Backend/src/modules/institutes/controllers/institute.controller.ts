
import { Request, Response } from "express";
import instituteService from "../services/institute.service";
import instituteDashboardService from "../services/institute-dashboard.service";

// Controller مسؤول عن استقبال طلبات إدارة المعاهد.
class InstituteController {
  async getActiveInstitutes(req: Request, res: Response): Promise<void> {
    try {
      const result = await instituteService.getActiveInstitutes({
        search: typeof req.query.search === "string"
          ? req.query.search
          : undefined,
        page: Number(req.query.page) || 1,
        limit: Number(req.query.limit) || 12,
      });

      res.status(200).json({
        success: true,
        message: "Institutes fetched successfully",
        data: result.institutes,
        pagination: result.pagination,
      });
    } catch (error) {
      console.error("Public institutes error:", error);
      res.status(500).json({
        success: false,
        message: "حدث خطأ أثناء جلب المعاهد",
      });
    }
  }

  async getDashboard(req: Request, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: "Authentication required",
      });
      return;
    }

    try {
      const dashboard = await instituteDashboardService.getDashboard(
        req.user.userId,
      );
      res.status(200).json({
        success: true,
        data: dashboard,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Institute dashboard failed";
      const notFound =
        message === "Institute owner not found" ||
        message === "Institute not found";

      if (!notFound) {
        console.error("Institute dashboard error:", error);
      }

      res.status(notFound ? 404 : 500).json({
        success: false,
        message: notFound
          ? message
          : "حدث خطأ أثناء جلب لوحة المعهد",
      });
    }
  }

  // إنشاء معهد جديد مع حساب صاحبه بواسطة مدير المنصة.
  async createInstitute(req: Request, res: Response): Promise<void> {
    try {
      // إرسال البيانات إلى Service لتنفيذ عملية الإنشاء.
      const result = await instituteService.createInstituteWithOwner(
        req.body
      );

      res.status(201).json({
        success: true,
        message: "Institute and owner created successfully",
        data: result,
      });
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : "Institute creation failed";

      // تحديد رمز الاستجابة المناسب.
      let statusCode = 400;

      if (message === "Owner email is already registered") {
        statusCode = 409;
      }

      res.status(statusCode).json({
        success: false,
        message,
      });
    }
  }

    // جلب بيانات المعهد الخاص بصاحب الحساب الحالي.
  async getMyInstitute(req: Request, res: Response): Promise<void> {
    try {
      // التأكد من وجود مستخدم مصادق عليه.
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: "Authentication required",
        });
        return;
      }

      // إرسال معرّف المستخدم إلى Service.
      const institute = await instituteService.getMyInstitute(
        req.user.userId
      );

      res.status(200).json({
        success: true,
        message: "Institute retrieved successfully",
        data: institute,
      });
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : "Failed to retrieve institute";

      // تحديد رمز الاستجابة حسب نوع الخطأ.
      let statusCode = 500;

      if (message === "Institute not found" ||
          message === "No institute is linked to this account") {
        statusCode = 404;
      }

      res.status(statusCode).json({
        success: false,
        message,
      });
    }
  }

  // تعديل بيانات المعهد الخاص بصاحب الحساب.
async updateMyInstitute(req: Request, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: "Authentication required",
      });
      return;
    }

    const result = await instituteService.updateMyInstitute(
      req.user.userId,
      req.body
    );

    res.status(200).json({
      success: true,
      message: "Institute updated successfully",
      data: result,
    });
  } catch (error) {
    const message = error instanceof Error
      ? error.message
      : "Institute update failed";

    let statusCode = 400;

    if (
      message === "Institute not found" ||
      message === "Institute owner not found" ||
      message === "No institute is linked to this account"
    ) {
      statusCode = 404;
    }

    if (message === "No valid fields provided for update") {
      statusCode = 400;
    }

    res.status(statusCode).json({
      success: false,
      message,
    });
  }
}

// عرض إعدادات المعهد.
async getMyInstituteSettings(req: Request, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: "Authentication required",
      });
      return;
    }

    const settings = await instituteService.getMyInstituteSettings(
      req.user.userId
    );

    res.status(200).json({
      success: true,
      message: "Institute settings retrieved successfully",
      data: settings,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to retrieve settings";

    res.status(message === "Institute not found" ? 404 : 400).json({
      success: false,
      message,
    });
  }
}

// تعديل إعدادات المعهد.
async updateMyInstituteSettings(req: Request, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: "Authentication required",
      });
      return;
    }

    const settings = await instituteService.updateMyInstituteSettings(
      req.user.userId,
      req.body
    );

    res.status(200).json({
      success: true,
      message: "Institute settings updated successfully",
      data: settings,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Settings update failed";

    const statusCode = message === "Institute not found" ? 404 : 400;

    res.status(statusCode).json({
      success: false,
      message,
    });
  }
}
}

// تصدير نسخة واحدة من Controller.
export default new InstituteController();
