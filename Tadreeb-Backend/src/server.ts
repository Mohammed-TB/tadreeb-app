import dotenv from "dotenv";
import app from "./app";
import connectDatabase from "./config/database";

// تحميل متغيرات البيئة من ملف .env.
dotenv.config();

// تحديد منفذ تشغيل الخادم.
const PORT = process.env.PORT || 5000;

// الاتصال بقاعدة البيانات أولًا، ثم تشغيل الخادم.
const startServer = async (): Promise<void> => {
  try {
    await connectDatabase();

    app.listen(PORT, () => {
      console.log(`Tadreeb API running at http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
};

startServer();