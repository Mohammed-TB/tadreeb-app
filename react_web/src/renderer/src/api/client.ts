import type { ApiEnvelope } from "../types";

export const apiBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim().replace(/\/+$/, "")
  || "http://127.0.0.1:5000";

export class ApiError extends Error {
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

interface RequestOptions extends Omit<RequestInit, "body"> {
  body?: BodyInit | Record<string, unknown>;
  authenticated?: boolean;
}

function readMessage(value: unknown): string | undefined {
  if (
    typeof value === "object" &&
    value !== null &&
    "message" in value &&
    typeof value.message === "string"
  ) {
    return value.message;
  }
  return undefined;
}

export async function request<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { authenticated = true, body, headers, ...init } = options;
  const requestHeaders = new Headers(headers);
  let requestBody: BodyInit | undefined;

  if (body instanceof FormData || body instanceof Blob || typeof body === "string") {
    requestBody = body;
  } else if (body !== undefined) {
    requestHeaders.set("Content-Type", "application/json");
    requestBody = JSON.stringify(body);
  }

  if (authenticated) {
    const token = await window.desktop.getAccessToken();
    if (!token) throw new ApiError("انتهت الجلسة. سجّل الدخول من جديد.", 401);
    requestHeaders.set("Authorization", `Bearer ${token}`);
  }

  let response: Response;
  try {
    response = await fetch(`${apiBaseUrl}${path}`, {
      ...init,
      body: requestBody,
      headers: requestHeaders,
    });
  } catch {
    throw new ApiError("تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت وحالة الخادم.");
  }

  const responseText = await response.text();
  let payload: unknown = null;
  if (responseText) {
    try {
      payload = JSON.parse(responseText) as unknown;
    } catch {
      throw new ApiError("أعاد الخادم استجابة غير مفهومة.", response.status);
    }
  }

  if (!response.ok) {
    if (response.status === 401 && authenticated) {
      window.dispatchEvent(new Event("tadreeb:session-expired"));
    }
    throw new ApiError(
      readMessage(payload) ?? "تعذر تنفيذ الطلب.",
      response.status,
    );
  }

  return payload as T;
}

export async function requestData<T>(
  path: string,
  options?: RequestOptions,
): Promise<T> {
  const response = await request<ApiEnvelope<T>>(path, options);
  if (!response.success) {
    throw new ApiError(response.message ?? "تعذر تحميل البيانات.");
  }
  return response.data;
}
