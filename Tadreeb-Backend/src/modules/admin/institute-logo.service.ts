import { Readable } from "stream";

import cloudinary from "../../config/cloudinary";

interface UploadedInstituteLogo {
  url: string;
  publicId: string;
}

class InstituteLogoService {
  async upload(buffer: Buffer): Promise<UploadedInstituteLogo> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: "tadreeb/institutes",
          resource_type: "image",
          allowed_formats: ["jpg", "jpeg", "png", "webp"],
        },
        (error, result) => {
          if (error || !result) {
            reject(error || new Error("Institute logo upload failed"));
            return;
          }

          resolve({
            url: result.secure_url,
            publicId: result.public_id,
          });
        },
      );

      Readable.from(buffer).pipe(uploadStream);
    });
  }

  async delete(publicId: string): Promise<void> {
    const result = await cloudinary.uploader.destroy(publicId, {
      resource_type: "image",
      type: "upload",
      invalidate: true,
    });

    if (result.result !== "ok" && result.result !== "not found") {
      throw new Error("Failed to delete unused institute logo");
    }
  }
}

export default new InstituteLogoService();
