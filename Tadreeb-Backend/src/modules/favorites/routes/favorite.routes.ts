
import { Router } from "express";
import authenticate, { authorizeRoles } from "../../../middlewares/auth.middleware";
import { UserRole } from "../../users/user.model";
import favoriteController from "../controllers/favorite.controller";



const router = Router();

// التحقق من تسجيل الدخول، والسماح للطلاب فقط.
router.use(
  authenticate,
  authorizeRoles(UserRole.STUDENT)
);

// إضافة دورة أو معهد إلى المفضلة.
router.post("/:targetType", favoriteController.addFavorite);

// حذف دورة أو معهد من المفضلة.
router.delete(
  "/:targetType/:targetId",
  favoriteController.removeFavorite
);

// جلب المفضلة حسب النوع.
router.get("/", favoriteController.getFavorites);

export default router;
