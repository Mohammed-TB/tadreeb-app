
import { Request, Response } from "express";
import authService from "./auth.service";

// Controller مسؤول عن استقبال طلبات المصادقة وإرجاع الاستجابات.
class AuthController {
  // تسجيل طالب جديد.
  async register(req: Request, res: Response): Promise<void> {
    try {
      const result = await authService.registerStudent(req.body);

      res.status(201).json({
        success: true,
        message: "Student registered successfully",
        data: result,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Registration failed";

      const statusCode =
        message === "Email is already registered" ? 409 : 400;

      res.status(statusCode).json({
        success: false,
        message,
      });
    }
  }

  // تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.
  async login(req: Request, res: Response): Promise<void> {
    try {
      const result = await authService.login(req.body);

      res.status(200).json({
        success: true,
        message: "Login successful",
        data: result,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Login failed";

      const statusCode =
        message === "Invalid email or password" ? 401 : 400;

      res.status(statusCode).json({
        success: false,
        message,
      });
    }
  }

  // تسجيل الدخول باستخدام Google للطلاب.
  async googleLogin(req: Request, res: Response): Promise<void> {
    try {
      // استقبال Google ID Token من تطبيق Flutter.
      const { idToken } = req.body;

      // تنفيذ التحقق من Google وإنشاء أو جلب حساب الطالب.
      const result = await authService.loginWithGoogle({ idToken });

      res.status(200).json({
        success: true,
        message: "Google login successful",
        data: result,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Google login failed";

      // تحديد رمز الاستجابة حسب نوع الخطأ.
      let statusCode = 400;

      if (
        message === "Google ID Token is required" ||
        message === "Invalid Google account"
      ) {
        statusCode = 401;
      } else if (
        message === "Your account is not active" ||
        message === "Google login is only available for students" ||
        message === "This email is linked to another Google account"
      ) {
        statusCode = 403;
      }

      res.status(statusCode).json({
        success: false,
        message,
      });
    }
  }
}

// تصدير نسخة واحدة من Controller.
export default new AuthController();
