
import mongoose from "mongoose";

// حالات الدورة.
export enum CourseStatus {
  DRAFT = "draft",
  PUBLISHED = "published",
  CLOSED = "closed",
  COMPLETED = "completed",
}

// بيانات إنشاء الدورة.
export interface CreateCourseInput {
  title: string;
  description: string;
  image?: string;
  category: string;
  price: number;
  depositAmount: number;
  capacity: number;
  startDate: Date | string;
  endDate: Date | string;
  location: string;

  // ماذا سيتعلم الطالب؟
  whatWillLearn?: string[];

  // مميزات الدورة.
  features?: string[];
}

// البيانات التي يمكن تعديلها.
export interface UpdateCourseInput {
  title?: string;
  description?: string;
  image?: string;
  category?: string;
  price?: number;
  depositAmount?: number;
  capacity?: number;
  startDate?: Date | string;
  endDate?: Date | string;
  location?: string;
  whatWillLearn?: string[];
  features?: string[];
}

// بيانات الدورة في قاعدة البيانات.
export interface ICourse {
  title: string;
  description: string;
  image?: string;
  category: string;
  price: number;
  depositAmount: number;
  capacity: number;
  enrolledCount: number;
  startDate: Date;
  endDate: Date;
  location: string;
  status: CourseStatus;
  instituteId: mongoose.Types.ObjectId;
  reservedCount: number;

  whatWillLearn: string[];
  features: string[];

  createdAt: Date;
  updatedAt: Date;
}
