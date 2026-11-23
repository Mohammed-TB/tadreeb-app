import mongoose, { Schema } from "mongoose";

export interface IStudent extends mongoose.Document {
  userId: mongoose.Types.ObjectId;
  name: string;
  englishName?: string;
  createdAt: Date;
  updatedAt: Date;
}

const studentSchema = new Schema<IStudent>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 150,
    },
    englishName: {
      type: String,
      trim: true,
      maxlength: 150,
    },
  },
  { timestamps: true },
);

const Student = mongoose.model<IStudent>("Student", studentSchema);

export default Student;
