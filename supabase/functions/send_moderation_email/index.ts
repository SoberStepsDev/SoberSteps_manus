import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { status: 200 });

  try {
    const payload = await req.json();
    if (payload.type !== "INSERT" || payload.table !== "moderation_queue") {
      return new Response("Nie INSERT moderation_queue", { status: 200 });
    }

    const record = payload.record;
    const content = record.content || "Treść niedostępna";
    const reason = record.reason || "Nieznany powód";

    // Tu wstaw swój email i klucz (np. Resend / SendGrid API)
    // Na start – prosty fetch do Resend (załóż darmowe konto na resend.com)
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "SoberSteps <noreply@soberstepsod.app>",
        to: ["twoj.email@gmail.com"],  // ← zmień na swój
        subject: "Nowy wpis do moderacji w 3AM Wall",
        html: `<p>Nowy toksyczny wpis:</p>
               <p><strong>Treść:</strong> ${content}</p>
               <p><strong>Powód:</strong> ${reason}</p>
               <p><strong>ID wpisu:</strong> ${record.row_id}</p>
               <p>Link do Supabase: https://supabase.com/dashboard/project/[project-id]/table/moderation_queue</p>`,
      }),
    });

    if (!res.ok) throw new Error("Email failed");

    return new Response("Email wysłany", { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response("Błąd", { status: 500 });
  }
});
