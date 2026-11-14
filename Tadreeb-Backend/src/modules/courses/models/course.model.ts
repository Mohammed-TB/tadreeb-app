import mongoose, { Schema } from "mongoose";
import { ICourse, CourseStatus } from "../types/course.types";

// مخطط بيانات الدورة.
const courseSchema = new Schema<ICourse>(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      minlength: 3,
      maxlength: 150,
    },

    description: {
      type: String,
      required: true,
      trim: true,
      maxlength: 3000,
    },

    image: {
      type: String,
      trim: true,
    },

    category: {
      type: String,
      required: true,
      trim: true,
    },

    // السعر الكامل للدورة.
    price: {
      type: Number,
      required: true,
      min: 0,
    },

    // العربون لا يمكن أن يتجاوز السعر الكامل.
    depositAmount: {
      type: Number,
      required: true,
      min: 0,
      validate: {
        validator: function (this: any, value: number) {
          // التأكد أن العربون لا يتجاوز السعر الكامل للدورة.
          return value <= this.price;
        },
        message: "Deposit cannot exceed course price",
      },
    },

    // السعة الكلية للمقاعد.
    capacity: {
      type: Number,
      required: true,
      min: 1,
    },

    // عدد المقاعد المؤكدة، لا يستقبله العميل.
    enrolledCount: {
      type: Number,
      default: 0,
      min: 0,
    },

    // المقاعد المحجوزة مؤقتًا بانتظار إكمال الدفع والموافقة.
    reservedCount: {
      type: Number,
      default: 0,
      min: 0,
    },


    // المهارات والمعارف التي سيكتسبها الطالب.
    whatWillLearn: {
      type: [String],
      required: true,
      default: [],
    },

    // مميزات الدورة.
    features: {
      type: [String],
      required: true,
      default: [],
    },

    startDate: {
      type: Date,
      required: true,
    },

    endDate: {
      type: Date,
      required: true,
    },

    location: {
      type: String,
      required: true,
      trim: true,
    },

    // حالة نشر الدورة.
    status: {
      type: String,
      enum: Object.values(CourseStatus),
      default: CourseStatus.DRAFT,
    },

    // المعهد المالك للدورة.
    instituteId: {
      type: Schema.Types.ObjectId,
      ref: "Institute",
      required: true,
      index: true,
    },
  },
  {
    timestamps: true,
  },
);

// منع تجاوز عدد المقاعد للسعة.
courseSchema.index({ instituteId: 1, status: 1 });

const Course = mongoose.model<ICourse>("Course", courseSchema);

export default Course;
