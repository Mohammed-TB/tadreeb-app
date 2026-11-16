import type { Server as HttpServer } from "node:http";
import jwt from "jsonwebtoken";
import { Server } from "socket.io";
import User, { UserRole, UserStatus } from "../modules/users/user.model";

let socketServer: Server | undefined;

const userRoom = (userId: string): string => `user:${userId}`;
const instituteRoom = (instituteId: string): string =>
  `institute:${instituteId}`;

export const initializeRealtimeGateway = (httpServer: HttpServer): Server => {
  if (socketServer) {
    throw new Error("Realtime gateway has already been initialized");
  }

  const io = new Server(httpServer, {
    cors: {
      origin: process.env.CLIENT_ORIGIN?.split(",") ?? "*",
      methods: ["GET", "POST"],
    },
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (typeof token !== "string" || !token) {
        return next(new Error("Authentication required"));
      }

      const secret = process.env.JWT_SECRET;
      if (!secret) {
        return next(new Error("Realtime authentication is unavailable"));
      }

      const decoded = jwt.verify(token, secret);
      if (typeof decoded === "string" || typeof decoded.userId !== "string") {
        return next(new Error("Invalid authentication token"));
      }

      const user = await User.findById(decoded.userId).select(
        "_id role status instituteId",
      );
      if (!user || user.status !== UserStatus.ACTIVE) {
        return next(new Error("Active account required"));
      }

      socket.data.userId = user.id;
      socket.data.role = user.role;
      socket.data.instituteId = user.instituteId?.toString();
      const rooms = [userRoom(user.id)];

      if (user.role === UserRole.STUDENT) {
        rooms.push("students");
      } else if (
        user.role === UserRole.INSTITUTE_OWNER &&
        user.instituteId
      ) {
        rooms.push(instituteRoom(user.instituteId.toString()));
      }

      await socket.join(rooms);
      next();
    } catch (error) {
      if (
        error instanceof jwt.JsonWebTokenError ||
        error instanceof jwt.TokenExpiredError
      ) {
        return next(new Error("Invalid or expired authentication token"));
      }

      console.error("[Realtime] Socket authentication failed:", error);
      next(new Error("Realtime authentication is unavailable"));
    }
  });

  socketServer = io;
  return io;
};

const getSocketServer = (): Server => {
  if (!socketServer) {
    throw new Error("Realtime gateway has not been initialized");
  }
  return socketServer;
};

const dispatch = (
  room: string,
  event: string,
  payload: Record<string, unknown>,
): void => {
  try {
    getSocketServer().to(room).emit(event, payload);
  } catch (error) {
    console.error(`[Realtime] Failed to emit ${event}:`, error);
  }
};

export const emitToStudents = (
  event: string,
  payload: Record<string, unknown>,
): void => {
  dispatch("students", event, payload);
};

export const emitToUser = (
  userId: string,
  event: string,
  payload: Record<string, unknown>,
): void => {
  dispatch(userRoom(userId), event, payload);
};

export const emitToInstitute = (
  instituteId: string,
  event: string,
  payload: Record<string, unknown>,
): void => {
  dispatch(instituteRoom(instituteId), event, payload);
};
