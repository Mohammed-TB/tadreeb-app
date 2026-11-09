import express from "express";
import cors from "cors";
import helmet from "helmet";
import authRoutes from "./modules/auth/auth.routes";

// إنشاء تطبيق Express الرئيسي.
const app = express();

// تفعيل الحماية الأساسية لترويسات HTTP.
app.use(helmet());

// السماح باستقبال طلبات من تطبيقات الواجهة.
app.use(cors());

// السماح بقراءة JSON المرسل في Request Body.
app.use(express.json());
// تسجيل جميع مسارات المصادقة تحت /api/auth.
app.use("/api/auth", authRoutes);

// مسار اختبار للتأكد من أن الخادم يعمل.
app.get("/api/health", (_req, res) => {
  res.status(200).json({
    success: true,
    message: "Tadreeb API is running",
  });
});

// تصدير التطبيق حتى نستخدمه في server.ts.
export default app;