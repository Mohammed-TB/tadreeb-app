
import { Router } from "express";

import authController from "./auth.controller";
import authenticate, {
  authorizeRoles,
} from "../../middlewares/auth.middleware";

import { UserRole } from "../users/user.model";

// إنشاء Router خاص بمسارات المصادقة.
const router = Router();

// تسجيل طالب جديد بالبريد وكلمة المرور.
router.post("/register", (req, res) =>
  authController.register(req, res)
);

// تسجيل الدخول بالبريد وكلمة المرور.
router.post("/login", (req, res) =>
  authController.login(req, res)
);

// تسجيل الدخول باستخدام حساب Google للطلاب.
router.post("/google", (req, res) =>
  authController.googleLogin(req, res)
);

// الحصول على بيانات المستخدم الحالي.
// هذا المسار محمي ويتطلب إرسال JWT صالح.
router.get("/me", authenticate, (req, res) => {
  const user = req.user;
  if (!user) {
    res.status(401).json({
      success: false,
      message: "Authentication required",
    });
    return;
  }

  res.status(200).json({
    success: true,
    message: "Authenticated successfully",
    user: {
      id: user.userId,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
      authProvider: user.authProvider,
    },
  });
});

// مسار تجريبي لا يستطيع الوصول إليه إلا مدير المنصة.
router.get(
  "/admin-test",
  authenticate,
  authorizeRoles(UserRole.ADMIN),
  (req, res) => {
    res.status(200).json({
      success: true,
      message: "Welcome Admin",
      user: req.user,
    });
  }
);

// تصدير Router لاستخدامه في app.ts.
export default router;
