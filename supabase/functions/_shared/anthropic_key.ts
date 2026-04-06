import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

export async function resolveAnthropicApiKey(
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
