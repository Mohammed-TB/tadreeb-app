import { Router, Request, Response } from "express";
import authenticate from "../../middlewares/auth.middleware";
import notificationService from "./notification.service";

const router = Router();
router.use(authenticate);

router.get("/", async (req: Request, res: Response) => {
  const page = Number(req.query.page ?? 1);
  const limit = Number(req.query.limit ?? 30);
  const result = await notificationService.getForUser(
    req.user!.userId,
    page,
    limit,
  );
  res.status(200).json({ success: true, data: result.data, unreadCount: result.unreadCount });
});

router.get("/unread-count", async (req: Request, res: Response) => {
  const result = await notificationService.getForUser(req.user!.userId, 1, 1);
  res.status(200).json({ success: true, data: { unreadCount: result.unreadCount } });
});

router.patch("/read-all", async (req: Request, res: Response) => {
  await notificationService.markAllRead(req.user!.userId);
  res.status(200).json({ success: true, data: { unreadCount: 0 } });
});

router.patch("/:recipientId/read", async (req: Request, res: Response) => {
  const recipientId = Array.isArray(req.params.recipientId)
    ? req.params.recipientId[0]
    : req.params.recipientId;
  await notificationService.markRead(req.user!.userId, recipientId);
  res.status(200).json({ success: true });
});

export default router;
