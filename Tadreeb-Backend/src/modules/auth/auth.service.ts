
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import { OAuth2Client } from "google-auth-library";

import User, {
  AuthProvider,
  UserRole,
  UserStatus,
} from "../users/user.model";
import { isValidE164Phone } from "../../shared/phone-number";
import greenApiPhoneVerificationService from "./green-api-phone-verification.service";
import Reservation from "../reservations/models/reservation.model";
import { BookingType } from "../reservations/types/reservation.types";

// بيانات التسجيل المطلوبة للطالب.
interface RegisterInput {
  name: string;
  email: string;
  password: string;
}

// بيانات تسجيل الدخول العادي.
interface LoginInput {
  email: string;
  password: string;
}

// بيانات تسجيل الدخول باستخدام Google.
interface GoogleLoginInput {
  idToken: string;
}

// إنشاء عميل Google للتحقق من هوية المستخدم.
const googleClient = new OAuth2Client();

// إنشاء JWT الخاص بتطبيق Tadreeb.
const generateToken = (userId: string, role: UserRole): string => {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new Error("JWT_SECRET is missing");
  }

  return jwt.sign(
    { userId, role },
    secret,
    { expiresIn: "7d" }
  );
};

// تجهيز بيانات المستخدم الآمنة لإرسالها إلى Flutter.
const getSafeUser = (user: any) => ({
  id: user.id,
  name: user.name,
  email: user.email,
  phone:user.phone,
  isPhoneVerified: user.isPhoneVerified ?? false,
  role: user.role,
  status: user.status,
});

// خدمة المصادقة المسؤولة عن جميع طرق تسجيل الدخول.
class AuthService {
  private hashOtp(userId: string, code: string): string {
    const secret = process.env.OTP_HASH_SECRET || process.env.JWT_SECRET || "";
    return crypto
      .createHmac("sha256", secret)
      .update(`${userId}:${code}`)
      .digest("hex");
  }

  async requestPhoneLink(userId: string, phone: string) {
    if (!isValidE164Phone(phone)) {
      throw new Error("Phone number must be in E.164 format");
    }

    const owner = await User.findOne({
      _id: { $ne: userId },
      phone,
      isPhoneVerified: true,
    });

    if (owner) {
      throw new Error("This phone number is already linked to another account");
    }

    const user = await User.findById(userId).select(
      "+phoneOtpHash +phoneOtpExpiresAt +phoneOtpAttempts",
    );

    if (!user || user.role !== UserRole.STUDENT || user.status !== UserStatus.ACTIVE) {
      throw new Error("Active student account required");
    }

    const code = crypto.randomInt(100000, 1000000).toString();
    user.phoneOtpHash = this.hashOtp(user.id, code);
    user.phoneOtpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    user.phoneOtpAttempts = 0;
    await user.save();

    try {
      await greenApiPhoneVerificationService.sendOtp(phone, code);
    } catch (error) {
      user.phoneOtpHash = undefined;
      user.phoneOtpExpiresAt = undefined;
      user.phoneOtpAttempts = 0;
      await user.save();
      throw error;
    }

    return {
      phone,
      expiresInSeconds: 10 * 60,
    };
  }

  async verifyPhoneLink(userId: string, phone: string, code: string) {
    if (!isValidE164Phone(phone)) {
      throw new Error("Phone number must be in E.164 format");
    }
    if (!/^\d{6}$/.test(code)) {
      throw new Error("Verification code must contain 6 digits");
    }

    const owner = await User.findOne({
      _id: { $ne: userId },
      phone,
      isPhoneVerified: true,
    });

    if (owner) {
      throw new Error("This phone number is already linked to another account");
    }

    const user = await User.findById(userId).select(
      "+phoneOtpHash +phoneOtpExpiresAt +phoneOtpAttempts",
    );

    if (!user || user.role !== UserRole.STUDENT || user.status !== UserStatus.ACTIVE) {
      throw new Error("Active student account required");
    }

    if (
      !user.phoneOtpHash ||
      !user.phoneOtpExpiresAt ||
      user.phoneOtpExpiresAt.getTime() < Date.now()
    ) {
      throw new Error("Verification code expired or not requested");
    }

    if ((user.phoneOtpAttempts ?? 0) >= 5) {
      throw new Error("Too many verification attempts");
    }

    const submittedHash = this.hashOtp(user.id, code);
    if (!crypto.timingSafeEqual(
      Buffer.from(user.phoneOtpHash, "hex"),
      Buffer.from(submittedHash, "hex"),
    )) {
      user.phoneOtpAttempts = (user.phoneOtpAttempts ?? 0) + 1;
      await user.save();
      throw new Error("Invalid verification code");
    }

    user.phone = phone;
    user.isPhoneVerified = true;
    user.phoneOtpHash = undefined;
    user.phoneOtpExpiresAt = undefined;
    user.phoneOtpAttempts = 0;
    await user.save();

    const result = await Reservation.updateMany(
      {
        studentPhone: phone,
        bookingType: BookingType.IN_PERSON,
        $or: [
          { studentId: { $exists: false } },
          { studentId: null },
        ],
      },
      {
        $set: { studentId: user._id },
      },
    );

    return {
      user: getSafeUser(user),
      linkedReservations: result.modifiedCount,
    };
  }

  // تسجيل طالب جديد بالبريد وكلمة المرور.
  async registerStudent(input: RegisterInput) {
    const { name, email, password } = input;

    // توحيد صيغة البريد الإلكتروني.
    const normalizedEmail = email.trim().toLowerCase();

    // التأكد من عدم وجود حساب بنفس البريد.
    const existingUser = await User.findOne({
      email: normalizedEmail,
    });

    if (existingUser) {
      throw new Error("Email is already registered");
    }

    // تشفير كلمة المرور قبل حفظها.
    const hashedPassword = await bcrypt.hash(password, 12);

    // إنشاء حساب طالب جديد.
    const user = await User.create({
      name,
      email: normalizedEmail,
      password: hashedPassword,
      role: UserRole.STUDENT,
      status: UserStatus.ACTIVE,
      authProvider: AuthProvider.LOCAL,
      isPhoneVerified: false,
    });

    // إصدار Token بعد نجاح التسجيل.
    const token = generateToken(user.id, user.role);

    return {
      user: getSafeUser(user),
      token,
    };
  }

  // تسجيل الدخول بالبريد الإلكتروني وكلمة المرور.
  async login(input: LoginInput) {
    const { email, password } = input;

    // البحث عن الحساب مع جلب كلمة المرور المخفية.
    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select("+password");

    if (!user || !user.password) {
      throw new Error("Invalid email or password");
    }

    // التحقق من صحة كلمة المرور.
    const isPasswordValid = await bcrypt.compare(
      password,
      user.password
    );

    if (!isPasswordValid) {
      throw new Error("Invalid email or password");
    }

    // منع الحسابات غير النشطة من تسجيل الدخول.
    if (user.status !== UserStatus.ACTIVE) {
      throw new Error("Your account is not active");
    }

    // إصدار JWT بعد نجاح المصادقة.
    const token = generateToken(user.id, user.role);

    return {
      user: getSafeUser(user),
      token,
    };
  }

  // تسجيل الدخول باستخدام Google للطلاب فقط.
  async loginWithGoogle(input: GoogleLoginInput) {
    const { idToken } = input;

    // التأكد من وجود Web Client ID في إعدادات البيئة.
    const clientId = process.env.GOOGLE_CLIENT_ID;

    if (!clientId) {
      throw new Error("GOOGLE_CLIENT_ID is missing");
    }

    if (!idToken) {
      throw new Error("Google ID Token is required");
    }

    // التحقق من صحة التوكن لدى Google.
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: clientId,
    });

    // استخراج بيانات المستخدم بعد نجاح التحقق.
    const payload = ticket.getPayload();

    if (
      !payload ||
      !payload.sub ||
      !payload.email ||
      payload.email_verified !== true
    ) {
      throw new Error("Invalid Google account");
    }

    const googleId = payload.sub;
    const email = payload.email.toLowerCase();
    const name = payload.name || email.split("@")[0];

    // البحث عن حساب مرتبط بمعرف Google.
    let user = await User.findOne({ googleId });

    // إذا لم نجد حسابًا بمعرف Google، نبحث بالبريد.
    if (!user) {
      user = await User.findOne({ email });

      if (user) {
        // Google Login مخصص للطلاب فقط.
        if (user.role !== UserRole.STUDENT) {
          throw new Error("Google login is only available for students");
        }

        // منع ربط حساب مرتبط مسبقًا بمعرف Google مختلف.
        if (user.googleId && user.googleId !== googleId) {
          throw new Error("This email is linked to another Google account");
        }

        // ربط حساب الطالب الحالي بحساب Google.
        user.googleId = googleId;
        user.authProvider = AuthProvider.GOOGLE;

        await user.save();
      }
    }

    // إنشاء حساب طالب جديد إذا لم يكن البريد مسجلًا.
    if (!user) {
      user = await User.create({
        name,
        email,
        googleId,
        role: UserRole.STUDENT,
        status: UserStatus.ACTIVE,
        authProvider: AuthProvider.GOOGLE,
      });
    }

    // منع الحسابات المعلقة أو الموقوفة من الدخول.
    if (user.status !== UserStatus.ACTIVE) {
      throw new Error("Your account is not active");
    }

    // التأكد مرة أخرى أن الحساب طالب.
    if (user.role !== UserRole.STUDENT) {
      throw new Error("Google login is only available for students");
    }

    // إصدار JWT الخاص بتطبيق Tadreeb.
    const token = generateToken(user.id, user.role);

    return {
      user: getSafeUser(user),
      token,
    };
  }
}

// تصدير نسخة واحدة من خدمة المصادقة.
export default new AuthService();
