-- Performance advisor: unindexed foreign keys (lint 0001)
-- Safe idempotent indexes for JOIN/DELETE CASCADE on referenced keys.

CREATE INDEX IF NOT EXISTS idx_community_posts_user_id
  ON public.community_posts (user_id);

CREATE INDEX IF NOT EXISTS idx_craving_surf_sessions_user_id
  ON public.craving_surf_sessions (user_id);

CREATE INDEX IF NOT EXISTS idx_daily_self_acts_user_id
  ON public.daily_self_acts (user_id);

CREATE INDEX IF NOT EXISTS idx_family_observers_subscriber_id
  ON public.family_observers (subscriber_id);

CREATE INDEX IF NOT EXISTS idx_future_letters_user_id
  ON public.future_letters (user_id);

CREATE INDEX IF NOT EXISTS idx_generated_posts_content_strategy_id
  ON public.generated_posts (content_strategy_id);

CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id
  ON public.journal_entries (user_id);

CREATE INDEX IF NOT EXISTS idx_milestones_achieved_user_id
  ON public.milestones_achieved (user_id);

CREATE INDEX IF NOT EXISTS idx_moderation_queue_reviewed_by
  ON public.moderation_queue (reviewed_by);

CREATE INDEX IF NOT EXISTS idx_return_to_self_wall_user_id
  ON public.return_to_self_wall (user_id);

CREATE INDEX IF NOT EXISTS idx_self_experiments_user_id
  ON public.self_experiments (user_id);

CREATE INDEX IF NOT EXISTS idx_three_am_wall_user_id
  ON public.three_am_wall (user_id);

CREATE INDEX IF NOT EXISTS idx_video_queue_content_strategy_id
  ON public.video_queue (content_strategy_id);
