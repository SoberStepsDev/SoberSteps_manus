import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const blocklist = /suicide|overdose|fentanyl|heroin|cocaine|crystal|meth|drug|kill|https?:\/\/|bit\.ly|t\.co/gi

Deno.serve(async (req) => {
  const { record } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') || '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
  )

  const outcome = record.outcome_text || ''
  const isFlagged = blocklist.test(outcome)

  if (isFlagged) {
    await supabase
      .from('moderation_queue')
      .insert({
        table_name: 'three_am_wall',
        row_id: record.id,
        reason: 'Auto-flagged: content matches blocklist',
      })

    const adminEmail = Deno.env.get('ADMIN_EMAIL') || 'admin@sobersteps.com'
    // Send email to admin
  } else {
    await supabase
      .from('three_am_wall')
      .update({ is_visible: true, auto_moderated_at: new Date().toISOString() })
      .eq('id', record.id)
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200 })
})
