
import cloudinary from "../../../config/cloudinary";
import { Readable } from "stream";

interface UploadedReceipt {
  publicId: string;
  format: string;
}

class ReceiptUploadService {
  async uploadReceipt(buffer: Buffer): Promise<UploadedReceipt> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: "tadreeb/receipts",
          resource_type: "image",
          type: "authenticated",
          allowed_formats: ["jpg", "jpeg", "png", "webp"],
        },
        (error, result) => {
          if (error || !result) {
            return reject(error || new Error("Receipt upload failed"));
          }

          resolve({
            publicId: result.public_id,
            format: result.format,
          });
        },
      );

      Readable.from(buffer).pipe(uploadStream);
    });
  }

  // إنشاء رابط موقّع صالح لمدة 5 دقائق.
  generateReceiptUrl(publicId: string, format: string): string {
    const expiresAt = Math.floor(Date.now() / 1000) + 5 * 60;

    return cloudinary.utils.private_download_url(publicId, format, {
      resource_type: "image",
      type: "authenticated",
      expires_at: expiresAt,
      attachment: false,
    });
  }

    // حذف سند قديم أو صورة لم ينجح حفظها في MongoDB.
  async deleteReceipt(publicId: string): Promise<void> {
    await cloudinary.uploader.destroy(publicId, {
      resource_type: "image",
      type: "authenticated",
      invalidate: true,
    });
  }
}

export default new ReceiptUploadService();
