
import mongoose, { Document, Schema } from "mongoose";

// الأدوار المتاحة داخل منصة Tadreeb.
export enum UserRole {
  STUDENT = "student",
  INSTITUTE_OWNER = "instituteOwner",
  ADMIN = "admin",
}

// حالة حساب المستخدم.
export enum UserStatus {
  ACTIVE = "active",
  PENDING = "pending",
  SUSPENDED = "suspended",
}

// طريقة إنشاء الحساب.
export enum AuthProvider {
  LOCAL = "local",
  GOOGLE = "google",
}

// وصف بيانات المستخدم داخل TypeScript.
export interface IUser extends Document {
  name: string;
  email: string;
  phone?: string;
  password?: string;
  googleId?: string;
  role: UserRole;
  status: UserStatus;
  authProvider: AuthProvider;
  instituteId?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

// مخطط المستخدم الذي سيُحفظ في MongoDB.
const userSchema = new Schema<IUser>(
  {
    // الاسم الكامل للمستخدم.
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 100,
    },

    // البريد الإلكتروني، ويُحفظ بأحرف صغيرة لمنع التكرار.
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    // رقم الهاتف اختياري.
    phone: {
      type: String,
      trim: true,
    },

    // كلمة المرور اختيارية لأن حساب Google لا يحتاج كلمة مرور محلية.
    // لا تُرجع في استعلامات المستخدم العادية.
    password: {
      type: String,
      select: false,
    },

    // معرّف حساب Google عند التسجيل باستخدام Google.
    googleId: {
      type: String,
      sparse: true,
      unique: true,
    },

    // دور المستخدم داخل النظام.
    role: {
      type: String,
      enum: Object.values(UserRole),
      default: UserRole.STUDENT,
      required: true,
    },

    // حالة الحساب وصلاحية استخدامه.
    status: {
      type: String,
      enum: Object.values(UserStatus),
      default: UserStatus.ACTIVE,
      required: true,
    },

    // مصدر المصادقة.
    authProvider: {
      type: String,
      enum: Object.values(AuthProvider),
      default: AuthProvider.LOCAL,
      required: true,
    },

    // المعهد المرتبط بصاحب المعهد، إن وجد.
    instituteId: {
      type: Schema.Types.ObjectId,
      ref: "Institute",
    },
  },
  {
    // إضافة createdAt و updatedAt تلقائيًا.
    timestamps: true,
  }
);

// إنشاء Model للتعامل مع مجموعة المستخدمين في MongoDB.
const User = mongoose.model<IUser>("User", userSchema);

export default User;
