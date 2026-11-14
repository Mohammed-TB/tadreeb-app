
import mongoose from "mongoose";
import bcrypt from "bcrypt";

import User, {
  AuthProvider,
  UserRole,
  UserStatus,
} from "../../users/user.model";



import {
  CreateInstituteWithOwnerInput,
  UpdateInstituteInput ,
  UpdateInstituteSettingsInput
} from "../types/institute.types";
import Institute, { InstituteStatus } from "../models/institute.model";


// خدمة إدارة المعاهد وإنشاء حسابات أصحابها.
class InstituteService {
  // إنشاء معهد جديد وحساب صاحبه داخل Transaction واحدة.
  async createInstituteWithOwner(input: CreateInstituteWithOwnerInput) {
    const { institute, owner } = input;

    // توحيد صيغة البريد الإلكتروني لصاحب المعهد.
    const normalizedEmail = owner.email.trim().toLowerCase();

    // التأكد من عدم وجود حساب سابق بنفس البريد.
    const existingUser = await User.findOne({
      email: normalizedEmail,
    });

    if (existingUser) {
      throw new Error("Owner email is already registered");
    }

    // التحقق من الحد الأدنى لكلمة المرور.
    if (owner.password.length < 8) {
      throw new Error("Owner password must be at least 8 characters");
    }

    // تشفير كلمة مرور صاحب المعهد.
    const hashedPassword = await bcrypt.hash(owner.password, 12);

    // تجهيز معرّفات العلاقة بين المستخدم والمعهد.
    const ownerId = new mongoose.Types.ObjectId();
    const instituteId = new mongoose.Types.ObjectId();

    // بدء جلسة MongoDB لإجراء Transaction.
    const session = await mongoose.startSession();

    try {
      let createdOwner: any;
      let createdInstitute: any;

      // تنفيذ العمليات كوحدة واحدة.
      await session.withTransaction(async () => {
        // إنشاء حساب صاحب المعهد.
        const owners = await User.create(
          [
            {
              _id: ownerId,
              name: owner.name.trim(),
              email: normalizedEmail,
              phone: owner.phone?.trim(),
              password: hashedPassword,
              role: UserRole.INSTITUTE_OWNER,
              status: UserStatus.ACTIVE,
              authProvider: AuthProvider.LOCAL,
              instituteId,
            },
          ],
          { session }
        );

        createdOwner = owners[0];

        // إنشاء المعهد وربطه بصاحبه.
        const institutes = await Institute.create(
          [
            {
              _id: instituteId,
              name: institute.name.trim(),
              description: institute.description?.trim(),
              phone: institute.phone.trim(),
              email: institute.email?.trim().toLowerCase(),
              address: institute.address.trim(),
              logo: institute.logo,
              ownerId,
              status: InstituteStatus.ACTIVE,
            },
          ],
          { session }
        );

        createdInstitute = institutes[0];
      });

      // إرجاع البيانات الآمنة دون كلمة المرور.
      return {
        institute: {
          id: createdInstitute.id,
          name: createdInstitute.name,
          phone: createdInstitute.phone,
          email: createdInstitute.email,
          address: createdInstitute.address,
          status: createdInstitute.status,
          ownerId: createdInstitute.ownerId,
        },
        owner: {
          id: createdOwner.id,
          name: createdOwner.name,
          email: createdOwner.email,
          phone: createdOwner.phone,
          role: createdOwner.role,
          status: createdOwner.status,
          instituteId: createdOwner.instituteId,
        },
      };
    } catch (error: any) {
      // تحويل خطأ البريد المكرر إلى رسالة واضحة.
      if (error?.code === 11000) {
        throw new Error("Owner email is already registered");
      }

      throw error;
    } finally {
      // إغلاق جلسة MongoDB دائمًا.
      await session.endSession();
    }
  }

    // جلب بيانات المعهد المرتبط بصاحب الحساب الحالي.
  async getMyInstitute(userId: string) {
    // البحث عن حساب صاحب المعهد.
    const owner = await User.findById(userId).select(
      "_id role instituteId"
    );

    // التأكد من وجود الحساب.
    if (!owner) {
      throw new Error("User account not found");
    }

    // التأكد من أن الحساب تابع لصاحب معهد.
    if (owner.role !== UserRole.INSTITUTE_OWNER) {
      throw new Error("Only institute owners can access this resource");
    }

    // التأكد من أن الحساب مرتبط بمعهد.
    if (!owner.instituteId) {
      throw new Error("No institute is linked to this account");
    }

    // جلب المعهد باستخدام المعرّف المحفوظ في حساب المستخدم.
    const institute = await Institute.findById(owner.instituteId)
      .select("-__v");

    // التأكد من وجود المعهد.
    if (!institute) {
      throw new Error("Institute not found");
    }

    // إرجاع بيانات المعهد.
    return institute;
  }

  // تعديل بيانات المعهد الخاص بصاحب الحساب.
async updateMyInstitute(userId: string, input: UpdateInstituteInput) {
  // التحقق من صاحب الحساب.
  const owner = await User.findById(userId).select("_id role instituteId");

  if (!owner || owner.role !== UserRole.INSTITUTE_OWNER) {
    throw new Error("Institute owner not found");
  }

  if (!owner.instituteId) {
    throw new Error("No institute is linked to this account");
  }

  // تحديد الحقول المسموح بتعديلها فقط.
  const updates: UpdateInstituteInput = {};

  if (input.name !== undefined) updates.name = input.name.trim();
  if (input.description !== undefined) updates.description = input.description.trim();
  if (input.phone !== undefined) updates.phone = input.phone.trim();
  if (input.email !== undefined) updates.email = input.email.trim().toLowerCase();
  if (input.address !== undefined) updates.address = input.address.trim();
  if (input.logo !== undefined) updates.logo = input.logo.trim();

  if (Object.keys(updates).length === 0) {
    throw new Error("No valid fields provided for update");
  }

  // تحديث المعهد المرتبط بصاحب الحساب فقط.
  const institute = await Institute.findOneAndUpdate(
    {
      _id: owner.instituteId,
      ownerId: owner._id,
    },
    { $set: updates },
    {
      new: true,
      runValidators: true,
    }
  );

  if (!institute) {
    throw new Error("Institute not found");
  }

  return institute;
}

// جلب إعدادات المعهد الحالي.
async getMyInstituteSettings(userId: string) {
  const owner = await User.findById(userId).select("role instituteId");

  if (!owner || owner.role !== UserRole.INSTITUTE_OWNER) {
    throw new Error("Institute owner not found");
  }

  if (!owner.instituteId) {
    throw new Error("No institute is linked to this account");
  }

  const institute = await Institute.findOne({
    _id: owner.instituteId,
    ownerId: owner._id,
  }).select("settings");

  if (!institute) {
    throw new Error("Institute not found");
  }

  return institute.settings;
}

// تعديل إعدادات المعهد الحالي.
async updateMyInstituteSettings(
  userId: string,
  input: UpdateInstituteSettingsInput
) {
  const hours = input.receiptResubmissionHours;

  // التحقق من أن المهلة عدد صحيح بين 1 و72 ساعة.
  if (
    !Number.isInteger(hours) ||
    hours === undefined ||
    hours < 1 ||
    hours > 72
  ) {
    throw new Error("Receipt resubmission hours must be between 1 and 72");
  }

  const owner = await User.findById(userId).select("role instituteId");

  if (!owner || owner.role !== UserRole.INSTITUTE_OWNER) {
    throw new Error("Institute owner not found");
  }

  if (!owner.instituteId) {
    throw new Error("No institute is linked to this account");
  }

  const institute = await Institute.findOneAndUpdate(
    {
      _id: owner.instituteId,
      ownerId: owner._id,
    },
    {
      $set: {
        "settings.receiptResubmissionHours": hours,
      },
    },
    {
      new: true,
      runValidators: true,
    }
  ).select("settings");

  if (!institute) {
    throw new Error("Institute not found");
  }

  return institute.settings;
}
}

// تصدير نسخة واحدة من الخدمة.
export default new InstituteService();
