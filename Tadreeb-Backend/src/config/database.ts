
import mongoose from "mongoose";

// إنشاء اتصال MongoDB Atlas بقاعدة بيانات Tadreeb.
const connectDatabase = async (): Promise<void> => {
  try {
    // قراءة رابط الاتصال من متغيرات البيئة.
    const mongoUri = process.env.MONGODB_URI;

    // التأكد من وجود رابط الاتصال.
    if (!mongoUri) {
      throw new Error(
        "MONGODB_URI is missing from environment variables"
      );
    }

    // الاتصال بقاعدة البيانات المطلوبة.
    await mongoose.connect(mongoUri, {
      dbName: "institutes_app",
    });

    // عرض رسالة نجاح الاتصال واسم قاعدة البيانات.
    console.log("MongoDB Atlas connected successfully");
    console.log(`Database: ${mongoose.connection.name}`);
  } catch (error) {
    // طباعة تفاصيل الخطأ عند فشل الاتصال.
    console.error("MongoDB connection failed:", error);

    // تمرير الخطأ إلى server.ts لإيقاف تشغيل الخادم.
    throw error;
  }
};

// تصدير الدالة لاستخدامها عند تشغيل الخادم.
export default connectDatabase;
