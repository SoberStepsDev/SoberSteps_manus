import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { resolveAnthropicApiKey } from "../_shared/anthropic_key.ts";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

const SYSTEM_CRASHLOG_NORMAL = `You are CrashLog — a raw, adult mirror. No therapy clichés, no soft padding.
Reply in at most 1–2 short lines total. Match the user's language (Polish if they write Polish, English if English, etc.).
Always end with exactly one question that starts with "Ciekawe…?" when replying in Polish, or "Curious…?" when replying in English — for other languages, use the same idea: one short question opening word meaning "curious" or "I wonder" with an ellipsis, matching that language.
No bullet points. No numbered lists. No direct commands like "you must".`;

const SYSTEM_CRASHLOG_LOOP = `You are CrashLog in LOOP mode: the user has hit a repeating pain pattern (4+ similar entries in 30 days). Be more direct, more personal, and rawer than in normal mode — still never abusive or dehumanizing.
Reply in at most 1–2 short lines total. Match the user's language.
Always end with exactly one question that starts with "Ciekawe…?" (Polish) or "Curious…?" (English), or the same convention in the user's language as in normal mode.
No bullet points. No lists.`;

const MAX_TEXT = 4000;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      return json({ error: "server_misconfigured" }, 500);
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    // Never log the token itself (JWT content).
    console.error("[crash-log-feedback] auth header present:", authHeader.length > 0);
    const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!jwt) return json({ error: "unauthorized", reason: "missing_auth_header" }, 401);

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) {
      console.error("[crash-log-feedback] jwt rejected:", userErr?.message ?? "unknown");
      return json({ error: "unauthorized", reason: "invalid_jwt" }, 401);
    }
    const userId = userData.user.id;

    const body = await req.json();
    const text = typeof body.text === "string" ? body.text.trim() : "";
    const mode = body.mode === "gentle" ? "gentle" : "deep";
    const loopMode = Boolean(body.loop_mode);

    if (text.length === 0) return json({ error: "text required" }, 400);
    if (text.length > MAX_TEXT) return json({ error: "text too long" }, 400);

    const today = new Date().toISOString().slice(0, 10);

    const { data: row } = await admin
      .from("crash_log_rate_limits")
      .select("count")
      .eq("user_id", userId)
      .eq("rate_date", today)
      .maybeSingle();

    const current = typeof row?.count === "number" ? row.count : 0;
    if (current >= 20) {
      return json({ error: "limit_reached" }, 429);
    }

    const apiKey = await resolveAnthropicApiKey(admin);
    if (!apiKey) return json({ error: "anthropic_key_unavailable" }, 500);

    const system = loopMode ? SYSTEM_CRASHLOG_LOOP : SYSTEM_CRASHLOG_NORMAL;
    const userPrompt =
      `Mode: ${mode}\nLoop pattern detected: ${loopMode ? "yes" : "no"}\nUser text:\n${text}`;

    const res = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-3-5-haiku-20241022",
        max_tokens: 120,
        system,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      console.error("[crash-log-feedback] Anthropic error:", res.status, err);
      return json({ error: "anthropic_error", status: res.status }, 502);
    }

    const data = await res.json();
    const reply = data?.content?.[0]?.text?.trim() ?? null;
    if (!reply) return json({ error: "empty_response" }, 502);

    if (current === 0) {
      const { error: insErr } = await admin.from("crash_log_rate_limits").insert({
        user_id: userId,
        rate_date: today,
        count: 1,
      });
      if (insErr) console.error("[crash-log-feedback] insert rate", insErr);
    } else {
      const { error: updErr } = await admin
        .from("crash_log_rate_limits")
        .update({ count: current + 1 })
        .eq("user_id", userId)
        .eq("rate_date", today);
      if (updErr) console.error("[crash-log-feedback] update rate", updErr);
    }

    return json({ reply });
  } catch (e) {
    console.error("[crash-log-feedback]", e);
    return json({ error: "internal_server_error" }, 500);
  }
});

function json(o: object, status = 200) {
  return new Response(JSON.stringify(o), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
