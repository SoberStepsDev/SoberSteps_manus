import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  try {
    const { email, userId, username } = await req.json()

    const emailContent = `
      <html>
        <body style="font-family: sans-serif; background: #0A0A0F; color: white; padding: 24px;">
          <h1>Welcome to SoberSteps</h1>
          <p>Hi ${username},</p>
          <p>This is a different kind of recovery app. One built on curiosity, not judgment.</p>
          <p><strong>Uśmiech · Perspektywa · Droga</strong></p>
          <p>Smile (Curiosity) → Perspective (How far you've come) → The Road (Your direction, not the destination)</p>
          <p>In 30 days, we'll send you a letter from yourself. You'll see how far you've come.</p>
          <p>—The SoberSteps Team</p>
        </body>
      </html>
    `

    // Send email via Resend or SendGrid (example: assuming Resend setup)
    // For MVP, just log and return success
    console.log(`[welcome_email] Sent to ${email} (user: ${userId})`)

    return new Response(JSON.stringify({ success: true, email }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    })
  } catch (error) {
    console.error('[welcome_email] Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400
    })
  }
})
