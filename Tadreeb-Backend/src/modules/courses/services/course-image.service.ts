import { Readable } from "stream";

import cloudinary from "../../../config/cloudinary";

interface UploadedCourseImage {
  url: string;
  publicId: string;
}

class CourseImageService {
  async upload(buffer: Buffer): Promise<UploadedCourseImage> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: "tadreeb/courses",
          resource_type: "image",
          allowed_formats: ["jpg", "jpeg", "png", "webp"],
        },
        (error, result) => {
          if (error || !result) {
            return reject(error || new Error("Course image upload failed"));
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
      throw new Error("Failed to delete unused course image");
    }
  }
}

export default new CourseImageService();
