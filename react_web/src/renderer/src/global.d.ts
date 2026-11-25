export {};

declare global {
  interface Window {
    desktop: {
      getAccessToken(): Promise<string | null>;
      storeAccessToken(token: string): Promise<void>;
      clearAccessToken(): Promise<void>;
    };
  }
}
