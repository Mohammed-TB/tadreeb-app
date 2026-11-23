import { app, BrowserWindow, ipcMain, safeStorage, screen } from "electron";
import { readFile, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const currentDirectory = fileURLToPath(new URL(".", import.meta.url));
const tokenFile = () => join(app.getPath("userData"), "session.enc");

function requireSecureStorage() {
  if (!safeStorage.isEncryptionAvailable()) {
    throw new Error("تعذر تفعيل التخزين الآمن على هذا الجهاز.");
  }
}

function registerSessionHandlers() {
  ipcMain.handle("session:get-token", async () => {
    requireSecureStorage();
    try {
      const encryptedToken = await readFile(tokenFile());
      return safeStorage.decryptString(encryptedToken);
    } catch (error) {
      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        error.code === "ENOENT"
      ) {
        return null;
      }
      throw error;
    }
  });

  ipcMain.handle("session:set-token", async (_event, token: unknown) => {
    if (typeof token !== "string" || token.length < 20 || token.length > 8192) {
      throw new Error("رمز الدخول غير صالح.");
    }
    requireSecureStorage();
    await writeFile(tokenFile(), safeStorage.encryptString(token), {
      mode: 0o600,
    });
  });

  ipcMain.handle("session:clear-token", async () => {
    await rm(tokenFile(), { force: true });
  });
}

function createWindow() {
  const { x, y, width: workWidth, height: workHeight } =
    screen.getPrimaryDisplay().workArea;
  const minWidth = Math.min(1024, Math.round(workWidth * 0.9));
  const minHeight = Math.min(640, Math.round(workHeight * 0.88));
  const width = Math.max(minWidth, Math.round(workWidth * 0.92));
  const height = Math.max(minHeight, Math.round(workHeight * 0.9));

  const window = new BrowserWindow({
    title: "Tadreeb | إدارة المعهد",
    x: x + Math.round((workWidth - width) / 2),
    y: y + Math.round((workHeight - height) / 2),
    width,
    height,
    minWidth,
    minHeight,
    backgroundColor: "#FAF5E9",
    autoHideMenuBar: true,
    webPreferences: {
      preload: join(currentDirectory, "../preload/index.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  window.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
  window.webContents.on("will-navigate", (event, url) => {
    const developmentOrigin = process.env.ELECTRON_RENDERER_URL
      ? new URL(process.env.ELECTRON_RENDERER_URL).origin
      : null;
    const isAllowed = developmentOrigin
      ? new URL(url).origin === developmentOrigin
      : url.startsWith("file://");
    if (!isAllowed) event.preventDefault();
  });

  if (process.env.ELECTRON_RENDERER_URL) {
    void window.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    void window.loadFile(join(currentDirectory, "../renderer/index.html"));
  }
}

app.whenReady().then(() => {
  registerSessionHandlers();
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
