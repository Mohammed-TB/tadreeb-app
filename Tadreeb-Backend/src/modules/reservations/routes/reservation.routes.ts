
import { Router } from "express";
import authenticate, {
  authorizeRoles,
} from "../../../middlewares/auth.middleware";

import { UserRole } from "../../users/user.model";
import reservationController from "../controllers/reservation.controller";
import upload from "../../../middlewares/upload.middleware";
import {
  validateReceiptImage,
} from "../../../middlewares/upload.middleware";

// =====================================================
// مسارات الطالب.
// =====================================================
export const studentReservationRouter = Router();

studentReservationRouter.use(authenticate);
studentReservationRouter.use(authorizeRoles(UserRole.STUDENT));

// إنشاء حجز إلكتروني.
studentReservationRouter.post("/", (req, res) =>
  reservationController.createOnline(req, res),
);

// عرض حجوزات الطالب.
studentReservationRouter.get("/my", (req, res) =>
  reservationController.getMyReservations(req, res),
);

// رفع سند الدفع.
studentReservationRouter.post(
  "/:reservationId/receipt",
  upload.single("receipt"),
  validateReceiptImage,
  (req, res) => reservationController.uploadReceipt(req, res),
);

studentReservationRouter.post(
  "/:reservationId/balance-payment",
  upload.single("receipt"),
  validateReceiptImage,
  (req, res) => reservationController.uploadBalancePaymentReceipt(req, res),
);

// عرض سند الطالب الخاص به فقط.
studentReservationRouter.get(
  "/:reservationId/receipt",
  (req, res) => reservationController.getReceiptUrl(req, res),
);
studentReservationRouter.get(
  "/payments/:paymentId/receipt",
  (req, res) => reservationController.getPaymentReceiptUrl(req, res),
);

// =====================================================
// مسارات صاحب المعهد.
// =====================================================
export const instituteReservationRouter = Router();

instituteReservationRouter.use(authenticate);
instituteReservationRouter.use(
  authorizeRoles(UserRole.INSTITUTE_OWNER),
);

// تسجيل طالب حضورياً.
instituteReservationRouter.post(
  "/in-person",
  upload.single("receipt"),
  validateReceiptImage,
  (req, res) => reservationController.createInPerson(req, res),
);

instituteReservationRouter.post(
  "/:reservationId/receipt/resubmit",
  upload.single("receipt"),
  validateReceiptImage,
  (req, res) => reservationController.resubmitInPersonReceipt(req, res),
);

// عرض حجوزات المعهد.
instituteReservationRouter.get("/", (req, res) =>
  reservationController.getInstituteReservations(req, res),
);

instituteReservationRouter.get("/:reservationId", (req, res) =>
  reservationController.getInstituteReservationById(req, res),
);

// البحث عن اسم طالب سابق ضمن تسجيلات المعهد حسب رقم الهاتف.
instituteReservationRouter.get("/student-lookup", (req, res) =>
  reservationController.lookupStudentByPhone(req, res),
);

// عرض سند حجز تابع للمعهد فقط.
instituteReservationRouter.get(
  "/:reservationId/receipt",
  (req, res) => reservationController.getReceiptUrl(req, res),
);
instituteReservationRouter.get(
  "/payments/:paymentId/receipt",
  (req, res) => reservationController.getPaymentReceiptUrl(req, res),
);

instituteReservationRouter.get(
  "/:reservationId/balance-payment/receipt",
  (req, res) => reservationController.getBalancePaymentReceiptUrl(req, res),
);

instituteReservationRouter.patch(
  "/:reservationId/balance-payment/approve",
  (req, res) => reservationController.approveBalancePayment(req, res),
);

instituteReservationRouter.patch(
  "/:reservationId/balance-payment/reject",
  (req, res) => reservationController.rejectBalancePayment(req, res),
);

instituteReservationRouter.patch(
  "/:reservationId/balance-payment/in-person",
  (req, res) => reservationController.recordInPersonBalancePayment(req, res),
);

instituteReservationRouter.post(
  "/:reservationId/balance-payment/transfer",
  upload.single("receipt"),
  validateReceiptImage,
  (req, res) => reservationController.recordInPersonTransferPayment(req, res),
);

// الموافقة على السند.
instituteReservationRouter.patch(
  "/:reservationId/approve",
  (req, res) => reservationController.approveReservation(req, res),
);


// رفض السند.
instituteReservationRouter.patch(
  "/:reservationId/reject",
  (req, res) => reservationController.rejectReservation(req, res),
);
