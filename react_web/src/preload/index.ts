import { contextBridge, ipcRenderer } from "electron";

const desktopApi = {
  getAccessToken: (): Promise<string | null> =>
    ipcRenderer.invoke("session:get-token"),
  storeAccessToken: (token: string): Promise<void> =>
    ipcRenderer.invoke("session:set-token", token),
  clearAccessToken: (): Promise<void> =>
    ipcRenderer.invoke("session:clear-token"),
};

contextBridge.exposeInMainWorld("desktop", desktopApi);
