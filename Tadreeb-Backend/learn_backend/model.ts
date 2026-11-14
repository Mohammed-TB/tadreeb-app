
import mongoose, { Schema } from "mongoose";

export enum MaintenanceStatus {
  PENDING = "pending",
  IN_PROGRESS = "in_progress",
  COMPLETED = "completed",
  CANCELLED = "cancelled",
}

const maintenanceSchema = new Schema(
  {
    customerName: {
      type: String,
      required: true,
      trim: true,
    },
    carModel: {
      type: String,
      required: true,
      trim: true,
    },
    serviceType: {
      type: String,
      required: true,
    },
    bookingDate: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: Object.values(MaintenanceStatus),
      default: MaintenanceStatus.PENDING,
    },
  },
  { timestamps: true }
);

const Maintenance = mongoose.model(
  "Maintenance",
  maintenanceSchema
);

export default Maintenance;
