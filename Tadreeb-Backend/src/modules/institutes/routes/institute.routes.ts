import { Router } from "express";

import instituteController from "../controllers/institute.controller";
import authenticate, {
  authorizeRoles,
} from "../../../middlewares/auth.middleware";

import { UserRole } from "../../users/user.model";

// Router خاص بإدارة المعاهد من الأدمن.
const router = Router();

// إنشاء معهد وحساب صاحبه.
// هذا المسار متاح لمدير المنصة فقط.
router.post(
  "/",
  authenticate,
  authorizeRoles(UserRole.ADMIN),
  (req, res) => instituteController.createInstitute(req, res)
);

// Router خاص بصاحب المعهد.
export const instituteOwnerRouter = Router();

// إحصاءات لوحة المعهد المقيّدة بالمعهد المرتبط بحساب صاحبه.
instituteOwnerRouter.get(
  "/me/dashboard",
  authenticate,
  authorizeRoles(UserRole.INSTITUTE_OWNER),
  (req, res) => instituteController.getDashboard(req, res),
);

// جلب بيانات المعهد المرتبط بصاحب الحساب الحالي.
instituteOwnerRouter.get(
  "/me",
  authenticate,
  authorizeRoles(UserRole.INSTITUTE_OWNER),
  (req, res) => instituteController.getMyInstitute(req, res)
);

// تعديل بيانات المعهد لصاحبه فقط.
instituteOwnerRouter.put(
  "/me",
  authenticate,
  authorizeRoles(UserRole.INSTITUTE_OWNER),
  (req, res) => instituteController.updateMyInstitute(req, res)
);

// عرض إعدادات المعهد.
instituteOwnerRouter.get(
  "/me/settings",
  authenticate,
  authorizeRoles(UserRole.INSTITUTE_OWNER),
  (req, res) => instituteController.getMyInstituteSettings(req, res)
);

// تعديل إعدادات المعهد.
instituteOwnerRouter.patch(
  "/me/settings",
  authenticate,
  authorizeRoles(UserRole.INSTITUTE_OWNER),
  (req, res) => instituteController.updateMyInstituteSettings(req, res)
);

export default router;