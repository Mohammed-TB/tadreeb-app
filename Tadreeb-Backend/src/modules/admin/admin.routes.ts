import { Router } from "express";

import authenticate, {
  authorizeRoles,
} from "../../middlewares/auth.middleware";
import { UserRole } from "../users/user.model";
import adminController from "./admin.controller";
import upload, { validateImageContent } from "../../middlewares/upload.middleware";

const router = Router();

router.post(
  "/institutes/with-logo",
  authenticate,
  authorizeRoles(UserRole.ADMIN),
  upload.single("logo"),
  validateImageContent,
  (req, res) => adminController.createInstituteWithLogo(req, res),
);

router.get(
  "/institutes",
  authenticate,
  authorizeRoles(UserRole.ADMIN),
  (req, res) => adminController.getInstitutes(req, res),
);

router.get(
  "/users",
  authenticate,
  authorizeRoles(UserRole.ADMIN),
  (req, res) => adminController.getUsers(req, res),
);

router.patch(
  "/users/:userId/suspend",
  authenticate,
  authorizeRoles(UserRole.ADMIN),
  (req, res) => adminController.suspendUser(req, res),
);

router.get(
  "/stats",
  authenticate,
  authorizeRoles(UserRole.ADMIN),
  (req, res) => adminController.getStats(req, res),
);

export default router;
