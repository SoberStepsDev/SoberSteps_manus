import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

async function resolveAnthropicApiKey(
  admin: SupabaseClient,
): Promise<string | null> {
  const fromEnv = Deno.env.get("ANTHROPIC_API_KEY")?.trim();
  if (fromEnv) return fromEnv;
  const { data, error } = await admin.rpc("get_anthropic_key_for_edge");
  if (error) {
    console.error("[anthropic] vault rpc", error);
    return null;
  }
  if (typeof data === "string" && data.length > 0) return data.trim();
  return null;
}

const SYSTEM_PROMPT = `You are Naomi — a warm, intuitive sobriety coach.
Respond in 1–2 short sentences (max 40 words).
Match the user's language (Polish if they write in Polish, English if English).
Never judge. Never give advice. Only reflect, notice, ask one gentle question.
Do not use bullet points or lists.`;

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
    const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!jwt) return json({ error: "unauthorized" }, 401);

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
    if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);
    const userId = userData.user.id;

    const { question_type, answer } = await req.json();
    if (!answer || typeof answer !== "string" || answer.trim().length === 0) {
      return json({ error: "answer required" }, 400);
    }

    const today = new Date().toISOString().slice(0, 10);

    const { data: row } = await admin
      .from("naomi_rate_limits")
      .select("count")
      .eq("user_id", userId)
      .eq("rate_date", today)
      .maybeSingle();

    const current = typeof row?.count === "number" ? row.count : 0;
    if (current >= 10) {
      return json({ error: "limit_reached" }, 429);
    }

    const apiKey = await resolveAnthropicApiKey(admin);
    if (!apiKey) return json({ error: "anthropic_key_unavailable" }, 500);

    const userPrompt = `Question type: ${question_type ?? "open"}\nUser wrote: "${answer.trim()}"`;

    const res = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-3-5-haiku-20241022",
        max_tokens: 80,
        system: SYSTEM_PROMPT,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      console.error("[naomi-feedback] Anthropic error:", res.status, err);
      return json({ error: "anthropic_error", status: res.status }, 502);
    }

    const data = await res.json();
    const feedback = data?.content?.[0]?.text?.trim() ?? null;
    if (!feedback) return json({ error: "empty_response" }, 502);

    if (current === 0) {
      const { error: insErr } = await admin.from("naomi_rate_limits").insert({
        user_id: userId,
        rate_date: today,
        count: 1,
      });
      if (insErr) console.error("[naomi-feedback] insert rate", insErr);
    } else {
      const { error: updErr } = await admin
        .from("naomi_rate_limits")
        .update({ count: current + 1 })
        .eq("user_id", userId)
        .eq("rate_date", today);
      if (updErr) console.error("[naomi-feedback] update rate", updErr);
    }

    return json({ feedback });
  } catch (e) {
    console.error("[naomi-feedback]", e);
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
