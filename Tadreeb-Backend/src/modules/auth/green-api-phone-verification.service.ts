class GreenApiPhoneVerificationService {
  async sendOtp(phone: string, code: string): Promise<void> {
    const baseUrl = (
      process.env.GREEN_API_URL?.trim() || "https://api.green-api.com"
    ).replace(/\/+$/, "");
    const instanceId = process.env.GREEN_API_INSTANCE_ID?.trim();
    const apiToken = process.env.GREEN_API_TOKEN?.trim();

    if (!instanceId || !apiToken) {
      throw new Error("Green-API WhatsApp configuration is missing");
    }

    const chatId = `${phone.replace(/^\+/, "")}@c.us`;
    const url =
      `${baseUrl}/waInstance${encodeURIComponent(instanceId)}` +
      `/sendMessage/${encodeURIComponent(apiToken)}`;

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        chatId,
        message:
          `رمز التحقق من Tadreeb هو ${code}.\n` +
          "صالح لمدة 10 دقائق ولا تشاركه مع أي شخص.",
      }),
    });

    const responseText = await response.text();
    if (!response.ok) {
      throw new Error(
        `Failed to send WhatsApp verification code: ${response.status} ${responseText}`,
      );
    }
  }
}

export default new GreenApiPhoneVerificationService();
