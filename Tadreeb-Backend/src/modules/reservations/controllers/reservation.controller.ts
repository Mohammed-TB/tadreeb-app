import { Request, Response } from "express";
import reservationService from "../services/reservation.service";
import { PaymentOption } from "../types/reservation.types";

class ReservationController {
  // معالجة أخطاء الخدمة.
  private handleError(res: Response, error: unknown) {
    const message =
      error instanceof Error ? error.message : "Server error";

    const status =
      message.includes("not found") ? 404 :
      message.includes("not available") || message.includes("full") ? 409 :
      message.includes("already have") ? 409 :
      message.includes("status changed") || message.includes("exceeds") ? 409 :
      message.includes("required") ? 400 :
      400;

    return res.status(status).json({
      success: false,
      message,
    });
  }

  // POST: حجز إلكتروني بواسطة الطالب.
  async createOnline(req: Request, res: Response) {
    try {
      console.log("🔥 BACKEND: createOnline reached");
      const { courseId, studentName, studentPhone, paymentOption } = req.body;

      if (
        typeof courseId !== "string" ||
        typeof studentName !== "string" ||
        typeof studentPhone !== "string" ||
        !paymentOption
      ) {
        return res.status(400).json({
          success: false,
          message: "Course ID, student name, phone, and payment option are required",
        });
      }

      const reservation =
        await reservationService.createOnlineReservation(
          req.user!.userId,
          courseId,
          studentName,
          studentPhone,
          paymentOption,
        );

      return res.status(201).json({
        success: true,
        message: "Online reservation created successfully",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  // POST: تسجيل حضوري بواسطة صاحب المعهد.
  async createInPerson(req: Request, res: Response) {
    try {
      const {
        courseId,
        studentName,
        studentPhone,
        paymentOption,
      } = req.body;

      if (
        typeof courseId !== "string" ||
        typeof studentName !== "string" ||
        typeof studentPhone !== "string"
      ) {
        return res.status(400).json({
          success: false,
          message: "Please provide valid student details",
        });
      }

      const reservation =
        await reservationService.createInPersonReservation(
          req.user!.userId,
          {
            courseId,
            studentName,
            studentPhone,
            paymentOption,
          },
        );

      return res.status(201).json({
        success: true,
        message: "In-person registration created successfully",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  
  // PATCH: الموافقة على سند التحويل.
  async approveReservation(req: Request, res: Response) {
    try {
      const reservationId = req.params.reservationId;

      if (typeof reservationId !== "string") {
        return res.status(400).json({
          success: false,
          message: "Invalid reservation ID",
        });
      }

      const reservation =
        await reservationService.approveReservation(
          req.user!.userId,
          reservationId,
        );

      return res.status(200).json({
        success: true,
        message: "Reservation approved successfully",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  // PATCH: رفض سند التحويل.
  async rejectReservation(req: Request, res: Response) {
    try {
      const reservationId = req.params.reservationId;
      const { reason } = req.body;

      if (
        typeof reservationId !== "string" ||
        typeof reason !== "string" ||
        !reason.trim()
      ) {
        return res.status(400).json({
          success: false,
          message: "Reservation ID and rejection reason are required",
        });
      }

      const reservation =
        await reservationService.rejectReservation(
          req.user!.userId,
          reservationId,
          reason,
        );

      return res.status(200).json({
        success: true,
        message: "Reservation rejected successfully",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }


  // GET: حجوزات الطالب.
  async getMyReservations(req: Request, res: Response) {
    try {
      const reservations = await reservationService.getMyReservations(
        req.user!.userId,
      );

      return res.status(200).json({
        success: true,
        data: reservations,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  // GET: جميع تسجيلات المعهد.
  async getInstituteReservations(req: Request, res: Response) {
    try {
      const reservations =
        await reservationService.getInstituteReservations(
          req.user!.userId,
        );

      return res.status(200).json({
        success: true,
        data: reservations,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  async lookupStudentByPhone(req: Request, res: Response) {
    try {
      const phone =
        typeof req.query.phone === "string" ? req.query.phone.trim() : "";
      const studentName = await reservationService.findStudentNameByPhone(
        req.user!.userId,
        phone,
      );

      return res.status(200).json({
        success: true,
        data: { studentName },
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  

  // POST: رفع سند التحويل الإلكتروني.
  async uploadReceipt(req: Request, res: Response) {
    try {
      const reservationId = req.params.reservationId;

      if (typeof reservationId !== "string") {
        return res.status(400).json({
          success: false,
          message: "Invalid reservation ID",
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Please select a receipt image",
        });
      }

      const reservation = await reservationService.uploadReceipt(
        req.user!.userId,
        reservationId,
        req.file.buffer,
      );

      return res.status(200).json({
        success: true,
        message: "Receipt uploaded successfully. Waiting for institute review.",
        data: {
          _id: reservation._id,
          status: reservation.status,
          paymentStatus: reservation.paymentStatus,
          amountToPay: reservation.amountToPay,
          amountPaid: reservation.amountPaid,
          message: "Receipt submitted successfully and is awaiting review.",
        },
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  async uploadBalancePaymentReceipt(req: Request, res: Response) {
    try {
      const reservationId = req.params.reservationId;
      if (typeof reservationId !== "string") {
        return res.status(400).json({
          success: false,
          message: "Invalid reservation ID",
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Please select a receipt image",
        });
      }

      const reservation = await reservationService.uploadBalancePaymentReceipt(
        req.user!.userId,
        reservationId,
        req.file.buffer,
      );

      return res.status(200).json({
        success: true,
        message: "Balance payment receipt submitted successfully",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  async approveBalancePayment(req: Request, res: Response) {
    try {
      const reservationId = req.params.reservationId;
      if (typeof reservationId !== "string") {
        return res.status(400).json({
          success: false,
          message: "Invalid reservation ID",
        });
      }
      const reservation = await reservationService.approveBalancePayment(
        req.user!.userId,
        reservationId,
      );
      return res.status(200).json({
        success: true,
        message: "Balance payment approved successfully",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  async rejectBalancePayment(req: Request, res: Response) {
    try {
      const reservationId = req.params.reservationId;
      if (typeof reservationId !== "string") {
        return res.status(400).json({
          success: false,
          message: "Invalid reservation ID",
        });
      }
      const { reason } = req.body;
      if (typeof reason !== "string" || !reason.trim()) {
        return res.status(400).json({
          success: false,
          message: "Rejection reason is required",
        });
      }

      const reservation = await reservationService.rejectBalancePayment(
        req.user!.userId,
        reservationId,
        reason,
      );
      return res.status(200).json({
        success: true,
        message: "Balance payment rejected",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  async recordInPersonBalancePayment(req: Request, res: Response) {
    try {
      const reservationId = req.params.reservationId;
      if (typeof reservationId !== "string") {
        return res.status(400).json({
          success: false,
          message: "Invalid reservation ID",
        });
      }

      const reservation = await reservationService.recordInPersonBalancePayment(
        req.user!.userId,
        reservationId,
      );
      return res.status(200).json({
        success: true,
        message: "Remaining balance recorded as received in person",
        data: reservation,
      });
    } catch (error) {
      return this.handleError(res, error);
    }
  }

  // GET: الحصول على رابط مؤقت للسند بعد التحقق من الصلاحية.
  async getReceiptUrl(req: Request, res: Response) {
  try {
    const reservationId = req.params.reservationId;

    if (typeof reservationId !== "string") {
      return res.status(400).json({
        success: false,
        message: "Invalid reservation ID",
      });
    }

    const result = await reservationService.getReceiptAccessUrl(
      req.user!.userId,
      req.user!.role,
      reservationId,
    );

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    return this.handleError(res, error);
  }
}

async getBalancePaymentReceiptUrl(req: Request, res: Response) {
  try {
    const reservationId = req.params.reservationId;
    if (typeof reservationId !== "string") {
      return res.status(400).json({
        success: false,
        message: "Invalid reservation ID",
      });
    }

    const result = await reservationService.getReceiptAccessUrl(
      req.user!.userId,
      req.user!.role,
      reservationId,
      "balance",
    );

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    return this.handleError(res, error);
  }
}


}

export default new ReservationController();