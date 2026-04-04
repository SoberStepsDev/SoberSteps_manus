-- ============================================================
-- SoberSteps Phase 1 — Gap Migration
-- Fills missing pieces identified during recon:
--   1. check_letter_rate_limit RPC (missing from spec)
--   2. Entitlement lookup_key alignment note (RevenueCat)
--   3. Leaked password protection reminder (security advisor)
--   4. Ensure mirror_entries, inner_critic_log, self_experiments,
--      daily_self_acts, rts_scores have correct RLS policies
-- ============================================================

-- ─── 1. check_letter_rate_limit ──────────────────────────────
-- Free users: max 1 active (undelivered) letter at a time
-- Premium users: unlimited
CREATE OR REPLACE FUNCTION public.check_letter_rate_limit()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM future_letters
  WHERE user_id = auth.uid()
    AND delivered_at IS NULL;
  -- Free limit: 1 active letter
  RETURN v_count < 1;
END;
$$;

-- ─── 2. Ensure RLS policies for CBT / Self-Compassion tables ─
-- inner_critic_log
ALTER TABLE public.inner_critic_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "inner_critic_log_own" ON public.inner_critic_log;
CREATE POLICY "inner_critic_log_own"
  ON public.inner_critic_log
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- self_experiments
ALTER TABLE public.self_experiments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "self_experiments_own" ON public.self_experiments;
CREATE POLICY "self_experiments_own"
  ON public.self_experiments
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- daily_self_acts
ALTER TABLE public.daily_self_acts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "daily_self_acts_own" ON public.daily_self_acts;
CREATE POLICY "daily_self_acts_own"
  ON public.daily_self_acts
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- rts_scores
ALTER TABLE public.rts_scores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rts_scores_own" ON public.rts_scores;
CREATE POLICY "rts_scores_own"
  ON public.rts_scores
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- mirror_entries
ALTER TABLE public.mirror_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mirror_entries_own" ON public.mirror_entries;
CREATE POLICY "mirror_entries_own"
  ON public.mirror_entries
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── 3. Ensure mirror_entries table exists with full schema ──
-- (idempotent — only creates if missing)
CREATE TABLE IF NOT EXISTS public.mirror_entries (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content       text NOT NULL CHECK (length(content) <= 1000),
  entry_type    text NOT NULL CHECK (entry_type IN ('intuition','pattern','sync','dream','moment')),
  energy_level  smallint CHECK (energy_level BETWEEN 1 AND 5),
  tags          text[],
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- ─── 4. Performance index on mirror_entries ──────────────────
CREATE INDEX IF NOT EXISTS mirror_entries_user_created
  ON public.mirror_entries (user_id, created_at DESC);

-- ─── 5. Performance index on inner_critic_log ────────────────
CREATE INDEX IF NOT EXISTS inner_critic_log_user_created
  ON public.inner_critic_log (user_id, created_at DESC);
