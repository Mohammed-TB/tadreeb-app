import mongoose, { Schema } from "mongoose";
import { IFavorite, FavoriteTargetType } from "../types/favorite.type";

const favoriteSchema = new Schema<IFavorite>(
  {
    studentId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    targetType: {
      type: String,
      enum: Object.values(FavoriteTargetType),
      required: true,
    },

    targetId: {
      type: Schema.Types.ObjectId,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// منع تكرار نفس العنصر في مفضلة الطالب.
favoriteSchema.index(
  { studentId: 1, targetType: 1, targetId: 1 },
  { unique: true }
);

const Favorite = mongoose.model<IFavorite>("Favorite", favoriteSchema);

export default Favorite;