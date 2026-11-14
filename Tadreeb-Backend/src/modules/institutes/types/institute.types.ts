
import mongoose from "mongoose";

// البيانات الأساسية للمعهد.
export interface CreateInstituteInput {
  name: string;
  description?: string;
  phone: string;
  email?: string;
  address: string;
  logo?: string;
}

// بيانات صاحب المعهد الذي سينشئه مدير المنصة.
export interface CreateInstituteOwnerInput {
  name: string;
  email: string;
  phone?: string;
  password: string;
}

// البيانات المطلوبة لإنشاء المعهد وصاحبه معًا.
export interface CreateInstituteWithOwnerInput {
  institute: CreateInstituteInput;
  owner: CreateInstituteOwnerInput;
}

// نتيجة عملية إنشاء المعهد وصاحبه.
export interface CreateInstituteResult {
  institute: {
    id: string;
    name: string;
    phone: string;
    email?: string;
    address: string;
    status: string;
    ownerId: mongoose.Types.ObjectId;
  };
  owner: {
    id: string;
    name: string;
    email: string;
    phone?: string;
    role: string;
    status: string;
    instituteId: mongoose.Types.ObjectId;
  };
}

// البيانات المسموح لصاحب المعهد بتعديلها.
export interface UpdateInstituteInput {
  name?: string;
  description?: string;
  phone?: string;
  email?: string;
  address?: string;
  logo?: string;
}

// إعدادات المعهد.
export interface InstituteSettings {
  // المدة المسموحة لإعادة رفع سند الدفع بالساعات.
  receiptResubmissionHours: number;
}

// البيانات المسموح بتعديلها من إعدادات المعهد.
export interface UpdateInstituteSettingsInput {
  receiptResubmissionHours?: number;
}
