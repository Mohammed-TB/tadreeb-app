import mongoose from "mongoose";

export enum FavoriteTargetType {
  COURSE = "course",
  INSTITUTE = "institute",
}

export interface IFavorite {
  studentId: mongoose.Types.ObjectId;
  targetType: FavoriteTargetType;
  targetId: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}