import express from "express";
import cors from "cors";
import helmet from "helmet";
import authRoutes from "./modules/auth/auth.routes";
import instituteRoutes from "./modules/institutes/routes/institute.routes";
import {
  instituteOwnerRouter,
} from "./modules/institutes/routes/institute.routes";
import courseRoutes from "./modules/courses/routes/course.routes";
import publicCourseRoutes from "./modules/courses/routes/public-course.routes";
import {
  studentReservationRouter,
  instituteReservationRouter,
} from "./modules/reservations/routes/reservation.routes";
import favoriteRoutes from "./modules/favorites/routes/favorite.routes";
import adminRoutes from "./modules/admin/admin.routes";


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


// تسجيل مسارات إدارة المعاهد، المحمية بصلاحية المدير.
app.use("/api/admin/institutes", instituteRoutes);
app.use("/api/admin", adminRoutes);
// مسارات إدارة المعهد لصاحبه.
app.use("/api/institutes", instituteOwnerRouter);



app.use("/api/courses", publicCourseRoutes);

app.use("/api/institutes/me/courses", courseRoutes);

// حجوزات الطالب الإلكترونية.
app.use("/api/reservations", studentReservationRouter);
app.use("/api/favorites", favoriteRoutes);

// تسجيلات صاحب المعهد الحضورية وعرض جميع التسجيلات.
app.use("/api/institutes/me/reservations", instituteReservationRouter);
// مسار اختبار للتأكد من أن الخادم يعمل.
app.get("/api/health", (_req, res) => {
  res.status(200).json({
    success: true,
    message: "Tadreeb API is running",
  });
});

// تصدير التطبيق حتى نستخدمه في server.ts.
export default app;