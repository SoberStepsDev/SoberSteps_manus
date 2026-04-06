import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const brevoApiKey = Deno.env.get("BREVO_API_KEY") || "";
const brevoApiUrl = "https://api.brevo.com/v3/smtp/email";

serve(async (req: Request) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    const { email, subject, message } = await req.json();

    if (!email || !subject || !message) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const response = await fetch(brevoApiUrl, {
      method: "POST",
      headers: {
        "api-key": brevoApiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        sender: { email: "noreply@sobersteps.app", name: "SoberSteps" },
        to: [{ email }],
        subject,
        htmlContent: message,
      }),
    });

    if (!response.ok) {
      return new Response(
        JSON.stringify({ error: "internal_server_error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(JSON.stringify({ sent: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "internal_server_error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
