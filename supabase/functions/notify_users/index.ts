// notify_users — SoberSteps Edge Function
// Implements all 11 notification types from spec (Faza 7)
// Called by Supabase cron or manually via POST
// Rate limit: max 3 pushes/day/user enforced server-side

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

const MILESTONE_DAYS = [1, 3, 7, 14, 30, 60, 90, 180, 365, 730, 1825];

async function sendPush(
  externalUserId: string,
  heading: string,
  content: string,
  data?: Record<string, unknown>,
): Promise<boolean> {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) return false;
  const res = await fetch("https://onesignal.com/api/v1/notifications", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify({
      app_id: ONESIGNAL_APP_ID,
      include_external_user_ids: [externalUserId],
      headings: { en: heading },
      contents: { en: content },
      data: data ?? {},
    }),
  });
  return res.ok;
}

async function canSendPush(userId: string): Promise<boolean> {
  const today = new Date().toISOString().slice(0, 10);
  const { data } = await supabase
    .from("return_to_self_notification_log")
    .select("id")
    .eq("user_id", userId)
    .gte("created_at", `${today}T00:00:00Z`);
  return (data?.length ?? 0) < 3;
}

async function logNotification(userId: string, type: string): Promise<void> {
  await supabase.from("return_to_self_notification_log").insert({
    user_id: userId,
    notification_type: type,
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const type: string = body.type ?? "daily_checkin_reminder";
    const nowHour = new Date().getUTCHours();

    // Fetch all active users with their sobriety data
    const { data: users, error } = await supabase
      .from("profiles")
      .select(
        "id, checkin_reminder_hour, sobriety_start_date, emergency_contact_name",
      )
      .not("sobriety_start_date", "is", null);

    if (error) throw error;
    if (!users?.length) return new Response(JSON.stringify({ notified: 0 }), { status: 200 });

    let notified = 0;

    for (const user of users) {
      if (!(await canSendPush(user.id))) continue;

      const startDate = new Date(user.sobriety_start_date);
      const daysSober = Math.floor(
        (Date.now() - startDate.getTime()) / 86400000,
      );
      const reminderHour = user.checkin_reminder_hour ?? 21;

      let heading = "";
      let content = "";
      let shouldSend = false;

      switch (type) {
        // 1. Daily check-in reminder
        case "daily_checkin_reminder":
          if (nowHour === reminderHour) {
            heading = "SoberSteps";
            content = "Jak dziś? Twój streak czeka.";
            shouldSend = true;
          }
          break;

        // 2. Near Miss streak (premium only — checked in app)
        case "near_miss_streak": {
          const { data: todayCheckin } = await supabase
            .from("journal_entries")
            .select("id")
            .eq("user_id", user.id)
            .gte("created_at", new Date().toISOString().slice(0, 10) + "T00:00:00Z")
            .limit(1);
          if (!todayCheckin?.length && nowHour === reminderHour + 1) {
            heading = "Nie przerywaj!";
            content = `Nie przerywaj swojego ${daysSober}-dniowego streaka!`;
            shouldSend = true;
          }
          break;
        }

        // 3. Pre-milestone: day before
        case "pre_milestone": {
          const nextMilestone = MILESTONE_DAYS.find((m) => m === daysSober + 1);
          if (nextMilestone) {
            heading = "Jutro coś ważnego";
            content = `Jutro: ${nextMilestone} dni. Jeden z tych dni, które pamiętasz.`;
            shouldSend = true;
          }
          break;
        }

        // 4. High craving follow-up
        case "high_craving_followup": {
          const yesterday = new Date(Date.now() - 86400000)
            .toISOString()
            .slice(0, 10);
          const { data: entry } = await supabase
            .from("journal_entries")
            .select("craving_level")
            .eq("user_id", user.id)
            .gte("created_at", `${yesterday}T00:00:00Z`)
            .lt("created_at", `${yesterday}T23:59:59Z`)
            .order("created_at", { ascending: false })
            .limit(1);
          if (entry?.[0]?.craving_level >= 8) {
            heading = "Jesteśmy tu";
            content = "Wczoraj było ciężko. Jak dziś? Jesteśmy tu.";
            shouldSend = true;
          }
          break;
        }

        // 5. Late night reminder
        case "late_night": {
          const { data: todayCheckin } = await supabase
            .from("journal_entries")
            .select("id")
            .eq("user_id", user.id)
            .gte("created_at", new Date().toISOString().slice(0, 10) + "T00:00:00Z")
            .limit(1);
          if (!todayCheckin?.length && nowHour === 22) {
            heading = "Prawie północ";
            content = "Prawie północ. Jeszcze dziś możesz to zrobić.";
            shouldSend = true;
          }
          break;
        }

        // 6. 3-day streak (one-time)
        case "three_day_streak":
          if (daysSober === 3) {
            heading = "3 dni!";
            content = "3 dni! Budujesz coś prawdziwego.";
            shouldSend = true;
          }
          break;

        // 7. Letter delivery handled by separate trigger

        // 8. Milestone achieved
        case "milestone_achieved": {
          const milestone = MILESTONE_DAYS.find((m) => m === daysSober);
          if (milestone) {
            heading = "Kamień milowy!";
            content = `Osiągnąłeś ${milestone} dni! Tap aby świętować.`;
            shouldSend = true;
          }
          break;
        }

        // 9. 3AM Wall follow-up (30min after unresolved post — handled in app)

        // 10. 7-day re-engagement
        case "reengagement": {
          const { data: lastOpen } = await supabase
            .from("profiles")
            .select("updated_at")
            .eq("id", user.id)
            .single();
          const lastOpenDate = new Date(lastOpen?.updated_at ?? 0);
          const daysSinceOpen = Math.floor(
            (Date.now() - lastOpenDate.getTime()) / 86400000,
          );
          if (daysSinceOpen >= 7) {
            heading = "Nadal tu jesteś";
            content = `${daysSober} dni bez używek. Nadal tu jesteś.`;
            shouldSend = true;
          }
          break;
        }

        // 11. Family observer milestone
        case "family_milestone": {
          const { data: observers } = await supabase
            .from("family_observers")
            .select("observer_email, subscriber_user_id")
            .eq("subscriber_user_id", user.id)
            .eq("status", "accepted");
          const milestone = MILESTONE_DAYS.find((m) => m === daysSober);
          if (milestone && observers?.length) {
            heading = "Twoja rodzina świętuje";
            content = `Osiągnąłeś ${milestone} dni. Twoi bliscy są z Ciebie dumni.`;
            shouldSend = true;
          }
          break;
        }
      }

      if (shouldSend && heading) {
        const sent = await sendPush(user.id, heading, content, {
          type,
          days_sober: daysSober,
        });
        if (sent) {
          await logNotification(user.id, type);
          notified++;
        }
      }
    }

    return new Response(JSON.stringify({ ok: true, notified }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[notify_users] error:", e);
    return new Response(JSON.stringify({ error: "internal_server_error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
