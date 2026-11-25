export type UserRole = "student" | "instituteOwner" | "admin";

export interface AuthUser {
  id: string;
  name: string;
  email: string;
  phone?: string;
  role: UserRole;
  status: "active" | "pending" | "suspended";
}

export interface Institute {
  _id: string;
  name: string;
  description?: string;
  email?: string;
  address?: string;
  phone?: string;
  logo?: string;
}

export type BalancePaymentPolicy = "fullRemainder" | "installments";

export interface InstituteSettings {
  receiptResubmissionHours: number;
  balancePaymentPolicy: BalancePaymentPolicy;
  minimumInstallmentAmount: number;
}

export interface InstituteDashboard {
  institute: { name: string };
  summary: {
    courses: { total: number; published: number };
    reservations: {
      total: number;
      thisMonth: number;
      confirmedThisMonth: number;
      pendingPaymentThisMonth: number;
      paymentSubmittedThisMonth: number;
      rejectedThisMonth: number;
      expiredThisMonth: number;
      cancelledThisMonth: number;
      receiptsToReview: number;
    };
    revenue: {
      total: number;
      monthly: Array<{ year: number; month: number; revenue: number }>;
    };
  };
  courseOccupancy: Array<{
    id: string;
    title: string;
    capacity: number;
    occupied: number;
  }>;
  recentReservations: Array<{
    id: string;
    studentName: string;
    courseTitle: string;
    status: ReservationStatus;
    createdAt: string;
  }>;
  alerts: {
    coursesStartingSoon: number;
    fullCourses: number;
  };
}

export type CourseStatus = "draft" | "published" | "closed" | "completed";

export interface Course {
  _id: string;
  title: string;
  description: string;
  image?: string;
  category: string;
  price: number;
  depositAmount: number;
  requiresEnglishName: boolean;
  capacity: number;
  enrolledCount: number;
  reservedCount: number;
  startDate: string;
  endDate: string;
  status: CourseStatus;
  location: string;
  whatWillLearn: string[];
  features: string[];
}

export interface CourseInput {
  title: string;
  description: string;
  category: string;
  price: number;
  depositAmount: number;
  capacity: number;
  startDate: string;
  endDate: string;
  location: string;
  requiresEnglishName: boolean;
  whatWillLearn: string[];
  features: string[];
}

export type ReservationStatus =
  | "pendingPayment"
  | "paymentSubmitted"
  | "confirmed"
  | "rejected"
  | "expired"
  | "cancelled";

export interface PaymentRecord {
  _id: string;
  amount: number;
  status?: string;
  method?: string;
  createdAt: string;
  hasReceipt?: boolean;
}

export interface PopulatedCourse {
  _id: string;
  title: string;
  price?: number;
  depositAmount?: number;
}

export interface Reservation {
  _id: string;
  studentName: string;
  studentPhone: string;
  studentEnglishName?: string;
  courseId: PopulatedCourse | string;
  bookingType: "online" | "inPerson";
  status: ReservationStatus;
  totalAmount: number;
  amountToPay: number;
  amountPaid: number;
  paymentStatus: "unpaid" | "partial" | "paid";
  balancePaymentAmount: number;
  balancePaymentStatus: "none" | "pending" | "approved" | "rejected";
  balancePaymentMethod?: "bankTransfer" | "inPerson";
  balancePaymentPolicy?: BalancePaymentPolicy;
  minimumInstallmentAmount?: number;
  balancePaymentRejectionReason?: string;
  rejectionReason?: string;
  receiptResubmissionDeadline?: string;
  hasReceipt?: boolean;
  hasBalanceReceipt?: boolean;
  attendanceStatus?: "notMarked" | "attended" | "absent";
  createdAt: string;
  payments: PaymentRecord[];
}

export interface AppNotification {
  id: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  entityType: "course" | "reservation";
  entityId: string;
  action: "openCourseDetails" | "openReservationDetails";
  isRead: boolean;
  createdAt: string;
}

export interface ApiEnvelope<T> {
  success: boolean;
  message?: string;
  data: T;
}
