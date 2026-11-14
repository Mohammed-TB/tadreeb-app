
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

// عرض سند الطالب الخاص به فقط.
studentReservationRouter.get(
  "/:reservationId/receipt",
  (req, res) => reservationController.getReceiptUrl(req, res),
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
instituteReservationRouter.post("/in-person", (req, res) =>
  reservationController.createInPerson(req, res),
);

// عرض حجوزات المعهد.
instituteReservationRouter.get("/", (req, res) =>
  reservationController.getInstituteReservations(req, res),
);

// عرض سند حجز تابع للمعهد فقط.
instituteReservationRouter.get(
  "/:reservationId/receipt",
  (req, res) => reservationController.getReceiptUrl(req, res),
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
