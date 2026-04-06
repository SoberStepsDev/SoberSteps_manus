import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const emailRe = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function htmlConfirmation(): string {
  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f1ec;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f1ec;">
<tr><td align="center" style="padding:28px 14px;">
<table role="presentation" width="100%" style="max-width:520px;background:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #e6e0d8;">
<tr><td style="background:#1a1a1a;padding:22px 24px;text-align:center;">
<div style="font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;font-size:10px;letter-spacing:0.22em;color:#c9a227;text-transform:uppercase;">SoberSteps</div>
<h1 style="margin:8px 0 0;font-family:Georgia,'Times New Roman',serif;font-size:20px;font-weight:400;color:#faf6f0;line-height:1.35;">Email confirmed</h1>
</td></tr>
<tr><td style="padding:26px 26px 8px;font-family:Georgia,'Times New Roman',serif;font-size:16px;line-height:1.65;color:#2a2622;">
<p style="margin:0 0 14px;">Hi,</p>
<p style="margin:0 0 14px;">Your email address is confirmed. You're officially part of the SoberSteps community — we're grateful you're here.</p>
<p style="margin:0;">Open the app anytime you need support. You're not alone on this path.</p>
</td></tr>
<tr><td style="padding:0 26px 24px;font-family:Georgia,'Times New Roman',serif;font-size:12px;line-height:1.5;color:#8a8278;border-top:1px solid #ebe6df;padding-top:16px;">
Crisis (US): SAMHSA <a href="tel:18006624357" style="color:#5c564f;">1-800-662-4357</a> — 24/7, free, confidential.
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;
}

async function ensureLeadRow(
  admin: SupabaseClient,
  emailNorm: string,
): Promise<{ id: string; confirmation_email_sent_at: string | null } | null> {
  const { data: row, error: selErr } = await admin
    .from("email_leads")
    .select("id, confirmation_email_sent_at")
    .eq("email", emailNorm)
    .maybeSingle();
  if (selErr) {
    console.error("[select email_leads]", selErr);
    return null;
  }
  if (row) return row;
  const { data: insRow, error: insErr } = await admin
    .from("email_leads")
    .insert({ email: emailNorm })
    .select("id, confirmation_email_sent_at")
    .single();
  if (insErr) {
    console.error("[insert email_leads]", insErr);
    return null;
  }
  return insRow;
}

async function sendConfirmationEmail(
  admin: SupabaseClient,
  email: string,
): Promise<boolean> {
  const html = htmlConfirmation();
  const plaintext = "Your email address is confirmed. You're officially part of the SoberSteps community.";

  const res = await admin.functions.invoke("send_welcome_email", {
    body: {
      email,
      subject: "Welcome to SoberSteps",
      html,
      plaintext,
    },
  });
  if (res.error) {
    console.error("[send_welcome_email]", res.error);
    return false;
  }
  return true;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const adminKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!adminKey || !supabaseUrl) {
      return json({ error: "Missing env" }, 500);
    }

    const admin = createClient(supabaseUrl, adminKey);
    const body = await req.json();
    const { email } = body;

    if (!email || !emailRe.test(email)) {
      return json({ error: "Invalid email" }, 400);
    }

    const emailNorm = email.toLowerCase().trim();
    const lead = await ensureLeadRow(admin, emailNorm);
    if (!lead) {
      return json({ error: "Failed to ensure lead row" }, 500);
    }

    if (lead.confirmation_email_sent_at) {
      return json({ message: "Already sent" }, 200);
    }

    const sent = await sendConfirmationEmail(admin, emailNorm);
    if (!sent) {
      return json({ error: "Failed to send email" }, 500);
    }

    const { error: updateErr } = await admin
      .from("email_leads")
      .update({ confirmation_email_sent_at: new Date().toISOString() })
      .eq("id", lead.id);
    if (updateErr) {
      console.error("[update lead]", updateErr);
    }

    return json({ message: "Email sent" }, 200);
  } catch (err) {
    console.error("[error]", err);
    return json({ error: String(err) }, 500);
  }
});
