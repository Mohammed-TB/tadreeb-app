import cron from "node-cron";
import { expireReservations } from "../modules/reservations/services/reservation-expiration.service";

let isRunning = false;

export const startReservationExpirationJob = (): void => {
  // تشغيل الفحص مرة كل دقيقة.
  cron.schedule("* * * * *", async () => {
    // منع تشغيل فحص جديد إذا كان الفحص السابق لم ينتهِ.
    if (isRunning) return;

    isRunning = true;

    try {
      const count = await expireReservations();

      if (count > 0) {
        console.log(
          `[Reservation Expiration] Expired ${count} reservation(s).`,
        );
      }
    } catch (error) {
      console.error("[Reservation Expiration] Error:", error);
    } finally {
      isRunning = false;
    }
  });

  console.log("[Reservation Expiration] Job started.");
};