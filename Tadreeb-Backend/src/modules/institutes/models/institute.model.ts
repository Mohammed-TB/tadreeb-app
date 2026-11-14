
import mongoose, { Document, Schema } from "mongoose";

// حالات المعهد داخل المنصة.
export enum InstituteStatus {
  ACTIVE = "active",
  PENDING = "pending",
  SUSPENDED = "suspended",
}

// وصف بيانات المعهد.
export interface IInstitute extends Document {
  name: string;
  description?: string;
  phone: string;
  email?: string;
  address: string;
  logo?: string;
  ownerId: mongoose.Types.ObjectId;
  status: InstituteStatus;
  // إعدادات المعهد.
settings: {
  // المهلة الافتراضية لإعادة رفع سند الدفع: ساعة واحدة.
  receiptResubmissionHours: {
    type: Number,
    default: 1,
    min: 1,
    max: 72,
    required: true,
  },
},
  createdAt: Date;
  updatedAt: Date;
}

// مخطط المعهد الذي سيُحفظ في MongoDB.
const instituteSchema = new Schema<IInstitute>(
  {
    // اسم المعهد.
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 150,
    },

    // وصف مختصر للمعهد.
    description: {
      type: String,
      trim: true,
      maxlength: 1000,
    },

    // رقم التواصل الخاص بالمعهد.
    phone: {
      type: String,
      required: true,
      trim: true,
    },

    // البريد الإلكتروني للمعهد.
    email: {
      type: String,
      lowercase: true,
      trim: true,
    },

    // عنوان المعهد.
    address: {
      type: String,
      required: true,
      trim: true,
    },

    // رابط شعار المعهد.
    logo: {
      type: String,
      trim: true,
    },

    // صاحب المعهد المرتبط بهذا السجل.
    ownerId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    // إعدادات المعهد.

    // حالة المعهد داخل المنصة.
    status: {
      type: String,
      enum: Object.values(InstituteStatus),
      default: InstituteStatus.PENDING,
      required: true,
    },

    // إعدادات المعهد.
settings: {
  // المهلة الافتراضية لإعادة رفع سند الدفع: ساعة واحدة.
  receiptResubmissionHours: {
    type: Number,
    default: 1,
    min: 1,
    max: 72,
    required: true,
  },
},
  },
  {
    // إضافة createdAt و updatedAt تلقائيًا.
    timestamps: true,
  }
);

// إنشاء Model للتعامل مع مجموعة المعاهد.
const Institute = mongoose.model<IInstitute>(
  "Institute",
  instituteSchema
);

export default Institute;
