
import multer from "multer";
import { fileTypeFromBuffer } from "file-type";
import { Request, Response, NextFunction } from "express";

// الاحتفاظ بالصورة في الذاكرة مؤقتاً قبل فحص محتواها.
const storage = multer.memoryStorage();

const upload = multer({
  storage,

  // الحد الأقصى لحجم الصورة 5MB.
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 1,
  },

  // فحص نوع الملف المعلن مبدئياً.
  fileFilter: (_req, file, callback) => {
    const allowedTypes = [
      "image/jpeg",
      "image/png",
      "image/webp",
    ];

    if (!allowedTypes.includes(file.mimetype)) {
      return callback(
        new Error("Only JPG, PNG and WEBP images are allowed"),
      );
    }

    callback(null, true);
  },
});

// التحقق من محتوى الصورة الحقيقي بعد استلامها.
export const validateImageContent = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    if (!req.file) {
      return next();
    }

    const detectedType = await fileTypeFromBuffer(req.file.buffer);

    const allowedExtensions = ["jpg", "png", "webp"];

    if (
      !detectedType ||
      !allowedExtensions.includes(detectedType.ext) ||
      !["image/jpeg", "image/png", "image/webp"].includes(
        detectedType.mime,
      )
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid image content. Only JPG, PNG and WEBP are allowed.",
      });
    }

    next();
  } catch {
    return res.status(400).json({
      success: false,
      message: "Could not validate image",
    });
  }
};

export const validateReceiptImage = validateImageContent;

export default upload;