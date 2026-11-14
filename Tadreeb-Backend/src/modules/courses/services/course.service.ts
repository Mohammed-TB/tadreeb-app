
import mongoose from "mongoose";
import User, { UserRole } from "../../users/user.model";
import Course from "../models/course.model";
import Institute, { InstituteStatus } from "../../institutes/models/institute.model";

import {
  CreateCourseInput,
  UpdateCourseInput,
  CourseStatus,
} from "../types/course.types";



// خدمة إدارة الدورات.
class CourseService {
  // التأكد أن المستخدم صاحب معهد مرتبط ونشط.
// التأكد من هوية صاحب المعهد وجلب معهده المرتبط بحسابه.
private async getOwnerInstitute(userId: string) {
  // جلب حساب المستخدم ومعرّف المعهد.
  const owner = await User.findById(userId).select("role instituteId");

  if (!owner || owner.role !== UserRole.INSTITUTE_OWNER) {
    throw new Error("Institute owner not found");
  }

  if (!owner.instituteId) {
    throw new Error("No institute is linked to this account");
  }

  // جلب المعهد باستخدام المعرّف المحفوظ في حساب صاحبه.
  const institute = await Institute.findById(owner.instituteId);

  if (!institute || institute.status !== InstituteStatus.ACTIVE) {
    throw new Error("Active institute not found");
  }

  return institute;
}

  // التحقق من بيانات السعر والعربون والسعة والتواريخ.
  private validateCourseData(input: {
    price?: number;
    depositAmount?: number;
    capacity?: number;
    startDate?: Date | string;
    endDate?: Date | string;
  }) {
    if (
      input.price !== undefined &&
      (!Number.isFinite(input.price) || input.price < 0)
    ) {
      throw new Error("Invalid course price");
    }

    if (
      input.depositAmount !== undefined &&
      (!Number.isFinite(input.depositAmount) ||
        input.depositAmount < 0)
    ) {
      throw new Error("Invalid deposit amount");
    }

    if (
      input.capacity !== undefined &&
      (!Number.isInteger(input.capacity) || input.capacity < 1)
    ) {
      throw new Error("Capacity must be a positive integer");
    }

    if (
      input.price !== undefined &&
      input.depositAmount !== undefined &&
      input.depositAmount > input.price
    ) {
      throw new Error("Deposit cannot exceed course price");
    }

    const start = input.startDate === undefined
      ? undefined
      : new Date(input.startDate);

    const end = input.endDate === undefined
      ? undefined
      : new Date(input.endDate);

    if (start && Number.isNaN(start.getTime())) {
      throw new Error("Invalid course start date");
    }

    if (end && Number.isNaN(end.getTime())) {
      throw new Error("Invalid course end date");
    }

    if (start && end && end <= start) {
      throw new Error("End date must be after start date");
    }
  }

  // إنشاء دورة جديدة للمعهد الحالي.
  async createCourse(userId: string, input: CreateCourseInput) {
    const institute = await this.getOwnerInstitute(userId); // INSTITUTE

    this.validateCourseData(input);

    if (
      input.price === undefined ||
      input.depositAmount === undefined ||
      input.capacity === undefined ||
      !input.title?.trim() ||
      !input.description?.trim() ||
      !input.category?.trim() ||
      !input.location?.trim() ||
      !input.startDate ||
      !input.endDate
    ) {
      throw new Error("All required course fields must be provided");
    }

    if (new Date(input.startDate) <= new Date()) {
      throw new Error("Course start date must be in the future");
    }

    return Course.create({
      title: input.title.trim(),
      description: input.description.trim(),
      image: input.image?.trim(),
      category: input.category.trim(),
      price: input.price,
      depositAmount: input.depositAmount,
      capacity: input.capacity,
      startDate: input.startDate,
      endDate: input.endDate,
      location: input.location.trim(),
      whatWillLearn: this.normalizeStringList(input.whatWillLearn),
      features: this.normalizeStringList(input.features),

      // الدورة تبدأ كمسودة.
      status: CourseStatus.DRAFT,

      // ربط الدورة بمعهد صاحب الحساب، وليس من Body.
      instituteId: new mongoose.Types.ObjectId(institute.id),
    });
  }

  // عرض جميع دورات المعهد الحالي.
  async getMyCourses(userId: string) {
    const institute = await this.getOwnerInstitute(userId);

    return Course.find({
      instituteId: new mongoose.Types.ObjectId(institute.id),
    }).sort({ createdAt: -1 });
  }

  // عرض دورة محددة مع التأكد من ملكيتها.
  async getMyCourseById(userId: string, courseId: string) {
    if (!mongoose.isValidObjectId(courseId)) {
      throw new Error("Invalid course ID");
    }

    const institute = await this.getOwnerInstitute(userId);

    const course = await Course.findOne({
      _id: courseId,
      instituteId: new mongoose.Types.ObjectId(institute.id),
    });

    if (!course) {
      throw new Error("Course not found");
    }

    return course;
  }

  // تعديل بيانات دورة مملوكة للمعهد الحالي.
  async updateCourse(
    userId: string,
    courseId: string,
    input: UpdateCourseInput
  ) {
    const course = await this.getMyCourseById(userId, courseId);

    if (course.status !== CourseStatus.DRAFT) {
      throw new Error("Only draft courses can be edited");
    }

    this.validateCourseData({
      price: input.price,
      depositAmount: input.depositAmount,
      capacity: input.capacity,
      startDate: input.startDate,
      endDate: input.endDate,
    });

    if (input.title !== undefined) {
      if (input.title.trim().length < 3) {
        throw new Error("Course title must be at least 3 characters");
      }
      course.title = input.title.trim();
    }

    if (input.description !== undefined) {
      course.description = input.description.trim();
    }

    if (input.image !== undefined) {
      course.image = input.image.trim();
    }

    if (input.category !== undefined) {
      course.category = input.category.trim();
    }

    if (input.location !== undefined) {
      course.location = input.location.trim();
    }

    if (input.whatWillLearn !== undefined) {
      course.whatWillLearn = this.normalizeStringList(input.whatWillLearn);
    }

    if (input.features !== undefined) {
      course.features = this.normalizeStringList(input.features);
    }

    if (input.price !== undefined) course.price = input.price;
    if (input.depositAmount !== undefined) {
      course.depositAmount = input.depositAmount;
    }

    if (input.capacity !== undefined) {
      if (input.capacity < course.enrolledCount) {
        throw new Error("Capacity cannot be less than enrolled students");
      }
      course.capacity = input.capacity;
    }

    if (input.startDate !== undefined) {
      course.startDate = new Date(input.startDate);
    }

    if (input.endDate !== undefined) {
      course.endDate = new Date(input.endDate);
    }

    // التحقق من السعر والعربون بعد دمج القيم الجديدة والقديمة.
    if (course.depositAmount > course.price) {
      throw new Error("Deposit cannot exceed course price");
    }

    if (course.endDate <= course.startDate) {
      throw new Error("End date must be after start date");
    }

    if (course.startDate <= new Date()) {
      throw new Error("Course start date must be in the future");
    }

    return course.save();
  }

  private normalizeStringList(values: string[] | undefined): string[] {
    return (values ?? []).map((value) => value.trim()).filter(Boolean);
  }

  // نشر دورة مسودة.
  async publishCourse(userId: string, courseId: string) {
    const course = await this.getMyCourseById(userId, courseId);

    if (course.status !== CourseStatus.DRAFT) {
      throw new Error("Only draft courses can be published");
    }

    if (course.startDate <= new Date()) {
      throw new Error("Course start date must be in the future");
    }

    course.status = CourseStatus.PUBLISHED;

    return course.save();
  }

  // إغلاق التسجيل في الدورة.
  async closeCourse(userId: string, courseId: string) {
    const course = await this.getMyCourseById(userId, courseId);

    if (course.status !== CourseStatus.PUBLISHED) {
      throw new Error("Only published courses can be closed");
    }

    course.status = CourseStatus.CLOSED;

    return course.save();
  }

  // حذف دورة مسودة فقط.
  async deleteCourse(userId: string, courseId: string) {
    const course = await this.getMyCourseById(userId, courseId);

    if (course.status !== CourseStatus.DRAFT || course.enrolledCount > 0) {
      throw new Error("Only empty draft courses can be deleted");
    }

    await course.deleteOne();

    return { id: courseId };
  }
}

export default new CourseService();
