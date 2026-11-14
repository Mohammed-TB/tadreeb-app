
import { Router } from "express";

import courseController from "../controllers/course.controller";

import authenticate, {
  authorizeRoles,
} from "../../../middlewares/auth.middleware";
import upload, {
  validateImageContent,
} from "../../../middlewares/upload.middleware";

import { UserRole } from "../../users/user.model";

// Router خاص بإدارة دورات صاحب المعهد.
const router = Router();

// جميع المسارات محمية لصاحب المعهد.
router.use(authenticate);
router.use(authorizeRoles(UserRole.INSTITUTE_OWNER));

// إنشاء دورة.
router.post(
  "/",
  upload.single("image"),
  validateImageContent,
  (req, res) => courseController.createCourse(req, res),
);

// عرض جميع دورات المعهد.
router.get("/", (req, res) =>
  courseController.getMyCourses(req, res)
);

// عرض دورة محددة.
router.get("/:courseId", (req, res) =>
  courseController.getMyCourseById(req, res)
);

// تعديل دورة.
router.put("/:courseId", (req, res) =>
  courseController.updateCourse(req, res)
);

// نشر دورة.
router.patch("/:courseId/publish", (req, res) =>
  courseController.publishCourse(req, res)
);

// إغلاق التسجيل.
router.patch("/:courseId/close", (req, res) =>
  courseController.closeCourse(req, res)
);

// حذف دورة مسودة.
router.delete("/:courseId", (req, res) =>
  courseController.deleteCourse(req, res)
);

export default router;
