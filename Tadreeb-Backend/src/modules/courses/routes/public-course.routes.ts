import { Router } from "express";
import publicCourseController from "../controllers/public-course.controller";

const router = Router();

// هذه المسارات عامة ولا تحتاج إلى تسجيل دخول.
router.get("/", (req, res) =>
  publicCourseController.getCourses(req, res),
);

router.get("/:courseId", (req, res) =>
  publicCourseController.getCourseById(req, res),
);

export default router;