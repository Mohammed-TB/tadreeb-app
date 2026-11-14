
import dotenv from "dotenv";
import mongoose from "mongoose";
import bcrypt from "bcrypt";

import  connectDatabase  from "../config/database";
import User, {
  AuthProvider,
  UserRole,
  UserStatus,
} from "../modules/users/user.model";

// تحميل متغيرات البيئة من ملف .env.
dotenv.config();

// إنشاء حساب مدير المنصة إذا لم يكن موجودًا.
const createAdmin = async (): Promise<void> => {
  try {
    // قراءة بيانات المدير من متغيرات البيئة.
    const name = process.env.ADMIN_NAME;
    const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
    const password = process.env.ADMIN_PASSWORD;

    // التأكد من توفير جميع البيانات المطلوبة.
    if (!name || !email || !password) {
      throw new Error("Admin environment variables are missing");
    }

    // التحقق من الحد الأدنى لطول كلمة المرور.
    if (password.length < 12) {
      throw new Error("Admin password must be at least 12 characters");
    }

    // الاتصال بقاعدة بيانات MongoDB.
    await connectDatabase();

    // منع إنشاء حساب مدير مكرر.
    const existingUser = await User.findOne({ email });

    if (existingUser) {
      throw new Error(
        "This email is already registered. No account was modified."
      );
    }

    // تشفير كلمة المرور قبل حفظها.
    const hashedPassword = await bcrypt.hash(password, 12);

    // إنشاء حساب المدير بصلاحيات المنصة.
    const admin = await User.create({
      name,
      email,
      password: hashedPassword,
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
      authProvider: AuthProvider.LOCAL,
    });

    // عرض معلومات غير حساسة لتأكيد نجاح الإنشاء.
    console.log("Platform Admin created successfully");
    console.log("Admin ID:", admin.id);
    console.log("Admin Email:", admin.email);
    console.log("Admin Role:", admin.role);
  } catch (error) {
    // عرض سبب الفشل دون طباعة بيانات الاعتماد.
    console.error(
      "Admin creation failed:",
      error instanceof Error ? error.message : "Unknown error"
    );

    process.exitCode = 1;
  } finally {
    // إغلاق اتصال قاعدة البيانات بعد انتهاء العملية.
    await mongoose.disconnect();
  }
};

// تشغيل عملية إنشاء المدير.
void createAdmin();
