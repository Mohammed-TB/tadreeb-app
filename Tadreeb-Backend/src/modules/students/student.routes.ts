import { Router } from "express";
import authenticate, {
  authorizeRoles,
} from "../../middlewares/auth.middleware";
import { UserRole } from "../users/user.model";
import studentController from "./student.controller";

const router = Router();

router.use(authenticate, authorizeRoles(UserRole.STUDENT));
router.get("/me", (req, res) => studentController.getMyProfile(req, res));
router.patch("/me", (req, res) => studentController.updateMyProfile(req, res));

export default router;
