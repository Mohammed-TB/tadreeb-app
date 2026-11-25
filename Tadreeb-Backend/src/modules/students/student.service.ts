import mongoose from "mongoose";
import Student, { IStudent } from "./student.model";
import User, { UserRole } from "../users/user.model";
import { normalizeFourPartName } from "../../shared/student-name";

export interface StudentProfile {
  id: string;
  userId: string;
  name: string;
  englishName?: string;
}

const toProfile = (student: IStudent): StudentProfile => ({
  id: student._id.toString(),
  userId: student.userId.toString(),
  name: student.name,
  ...(student.englishName ? { englishName: student.englishName } : {}),
});

class StudentService {
  async ensureProfile(
    userId: mongoose.Types.ObjectId | string,
    name: string,
  ): Promise<IStudent> {
    const student = await Student.findOneAndUpdate(
      { userId },
      { $setOnInsert: { userId, name: name.trim() } },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true },
    );
    return student;
  }

  async getMyProfile(userId: string): Promise<StudentProfile> {
    const user = await User.findOne({ _id: userId, role: UserRole.STUDENT });
    if (!user) {
      throw new Error("Student account not found");
    }

    return toProfile(await this.ensureProfile(user._id, user.name));
  }

  async updateMyProfile(
    userId: string,
    input: { name: unknown; englishName?: unknown },
  ): Promise<StudentProfile> {
    if (typeof input.name !== "string") {
      throw new Error("Student name is required");
    }
    const name = normalizeFourPartName(input.name);
    if (!name) {
      throw new Error("Student name must include the full four-part name");
    }

    let englishName: string | undefined;
    if (input.englishName !== undefined && input.englishName !== null) {
      if (typeof input.englishName !== "string") {
        throw new Error("English name must be text");
      }
      englishName = input.englishName.trim() || undefined;
      if (englishName && englishName.length > 150) {
        throw new Error("English name cannot exceed 150 characters");
      }
    }

    const session = await mongoose.startSession();
    try {
      let updated: IStudent | null = null;
      await session.withTransaction(async () => {
        const user = await User.findOne({
          _id: userId,
          role: UserRole.STUDENT,
        }).session(session);
        if (!user) {
          throw new Error("Student account not found");
        }

        user.name = name;
        await user.save({ session });

        updated = await Student.findOneAndUpdate(
          { userId: user._id },
          {
            $set: { name, englishName },
            $setOnInsert: { userId: user._id },
          },
          {
            new: true,
            upsert: true,
            runValidators: true,
            setDefaultsOnInsert: true,
            session,
          },
        );
      });

      if (!updated) {
        throw new Error("Student profile update returned no result");
      }
      return toProfile(updated);
    } finally {
      await session.endSession();
    }
  }
}

export default new StudentService();
