import { Request, Response } from "express";
import studentService from "./student.service";

class StudentController {
  async getMyProfile(req: Request, res: Response): Promise<void> {
    try {
      const profile = await studentService.getMyProfile(req.user!.userId);
      res.status(200).json({ success: true, data: profile });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Failed to get student profile";
      res.status(message === "Student account not found" ? 404 : 400).json({
        success: false,
        message,
      });
    }
  }

  async updateMyProfile(req: Request, res: Response): Promise<void> {
    try {
      const profile = await studentService.updateMyProfile(
        req.user!.userId,
        req.body,
      );
      res.status(200).json({
        success: true,
        message: "Student profile updated successfully",
        data: profile,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Failed to update student profile";
      const status = message === "Student account not found" ? 404 : 400;
      res.status(status).json({ success: false, message });
    }
  }
}

export default new StudentController();
