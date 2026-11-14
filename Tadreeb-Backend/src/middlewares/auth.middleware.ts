
import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

import User, {
  UserStatus,
  UserRole,
} from "../modules/users/user.model";

// البيانات التي نستخرجها من JWT.
export interface AuthPayload {
  userId: string;
  name: string;
  email: string;
  phone?: string;
  role: UserRole;
  status: UserStatus;
  authProvider: string;

    // معرّف المعهد المرتبط بحساب المستخدم.
  instituteId?: string;
}

// إضافة بيانات المستخدم إلى Express Request.
declare global {
  namespace Express {
    interface Request {
      user?: AuthPayload;
    }
  }
}

// التحقق من هوية المستخدم وحالة حسابه في قاعدة البيانات.
const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // قراءة Authorization Header.
    const authHeader = req.headers.authorization;

    // التأكد من وجود Bearer Token.
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({
        success: false,
        message: "Authentication token is required",
      });
      return;
    }

    // استخراج Token.
    const token = authHeader.split(" ")[1];

    const secret = process.env.JWT_SECRET;

    if (!secret) {
      throw new Error("JWT_SECRET is missing");
    }

    // التحقق من صحة توقيع Token وصلاحيته.
    const decoded = jwt.verify(token, secret);

    // التأكد من صحة البيانات الموجودة داخل Token.
    if (
      typeof decoded === "string" ||
      typeof decoded.userId !== "string"
    ) {
      res.status(401).json({
        success: false,
        message: "Invalid authentication token",
      });
      return;
    }

    // البحث عن المستخدم في MongoDB.
const user = await User.findById(decoded.userId).select(
  "_id name email phone role status authProvider instituteId"
);

    // رفض الطلب إذا لم يعد المستخدم موجودًا.
    if (!user) {
      res.status(401).json({
        success: false,
        message: "User account not found",
      });
      return;
    }

    // منع الحسابات المعلقة أو الموقوفة.
    if (user.status !== UserStatus.ACTIVE) {
      res.status(403).json({
        success: false,
        message: "Your account is not active",
      });
      return;
    }

    // استخدام الدور الحالي من قاعدة البيانات وليس من Token.
    req.user = {
      userId: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
      authProvider: user.authProvider,


  // تحويل ObjectId إلى String لتسهيل استخدامه في API.
  instituteId: user.instituteId?.toString(),
    };

    // السماح باستكمال الطلب.
    next();
  } catch (error) {
    // أخطاء JWT أو قاعدة البيانات لا تسمح بالوصول.
    if (
      error instanceof jwt.JsonWebTokenError ||
      error instanceof jwt.TokenExpiredError
    ) {
      res.status(401).json({
        success: false,
        message: "Invalid or expired token",
      });
      return;
    }

    console.error("Authentication middleware error:", error);

    res.status(500).json({
      success: false,
      message: "Authentication failed",
    });
  }
};

// Middleware للتحقق من أدوار المستخدم المسموح لها بالوصول.
export const authorizeRoles = (...allowedRoles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    // يجب أن يمر المستخدم أولًا من authenticate.
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: "Authentication required",
      });
      return;
    }

    // التأكد أن دور المستخدم ضمن الأدوار المسموحة.
    if (!allowedRoles.includes(req.user.role)) {
      res.status(403).json({
        success: false,
        message: "You do not have permission to access this resource",
      });
      return;
    }

    next();
  };
};

export default authenticate;
