-- Migration: anon_auth_rls_fix
-- Purpose: Support signInAnonymously() in onboarding (Cursor AI sessions 2-3)

-- 1. profiles INSERT: allow authenticated (incl. anonymous) users to insert own row
DROP POLICY IF EXISTS profiles_insert_own ON profiles;
CREATE POLICY profiles_insert_own ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- 2. rts_scores INSERT: allow authenticated users (incl. anonymous)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'rts_scores' AND policyname = 'rts_insert_own'
  ) THEN
    CREATE POLICY rts_insert_own ON rts_scores
      FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 3. email_leads INSERT: allow unauthenticated (step 2 fires before signInAnonymously)
DROP POLICY IF EXISTS leads_insert_validated ON email_leads;
CREATE POLICY leads_insert_validated ON email_leads
  FOR INSERT
  WITH CHECK (email ~* '^[^@]+@[^@]+\.[^@]+$');
