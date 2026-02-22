-- =============================================================================
-- Fix Friendships Foreign Key Relationships for PostgREST
-- =============================================================================
-- Issue: PostgrestException PGRST200 - Cannot find relationship between
-- 'friendships' and 'user_id' because PostgREST needs explicit FK naming
-- =============================================================================

-- Drop existing foreign key constraints
ALTER TABLE public.friendships
  DROP CONSTRAINT IF EXISTS friendships_user_id_fkey,
  DROP CONSTRAINT IF EXISTS friendships_friend_id_fkey;

-- Clean up orphaned records before adding foreign key constraints
-- Delete friendships where user_id doesn't exist in profiles
DELETE FROM public.friendships
WHERE user_id NOT IN (SELECT id FROM public.profiles);

-- Delete friendships where friend_id doesn't exist in profiles
DELETE FROM public.friendships
WHERE friend_id NOT IN (SELECT id FROM public.profiles);

-- Re-add foreign keys with explicit naming that PostgREST can recognize
-- This allows queries like: .select('*, user:user_id(*), friend:friend_id(*)')
ALTER TABLE public.friendships
  ADD CONSTRAINT friendships_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(id)
    ON DELETE CASCADE;

ALTER TABLE public.friendships
  ADD CONSTRAINT friendships_friend_id_fkey
    FOREIGN KEY (friend_id)
    REFERENCES public.profiles(id)
    ON DELETE CASCADE;

-- Add comment explaining the relationship
COMMENT ON CONSTRAINT friendships_user_id_fkey ON public.friendships IS
  'FK to profiles table - the user who initiated the friendship';
COMMENT ON CONSTRAINT friendships_friend_id_fkey ON public.friendships IS
  'FK to profiles table - the user who received the friendship request';

-- =============================================================================
-- Enable Realtime for Messages and Friendships
-- =============================================================================

-- Enable realtime for friendships table (for live friend request notifications)
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;

-- Enable realtime for messages table (for live chat)
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- Verify realtime is enabled
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename IN ('friendships', 'messages')
  ) THEN
    RAISE NOTICE '✅ Realtime enabled for friendships and messages tables';
  ELSE
    RAISE WARNING '⚠️ Realtime may not be enabled. Check publication settings.';
  END IF;
END $$;

-- =============================================================================
-- Verification Queries
-- =============================================================================

SELECT
  '✅ Foreign Key Constraints' as check_type,
  constraint_name,
  table_name,
  column_name
FROM information_schema.key_column_usage
WHERE table_name = 'friendships'
  AND table_schema = 'public'
  AND constraint_name LIKE '%fkey%'
ORDER BY constraint_name;

SELECT
  '✅ Realtime Publications' as check_type,
  schemaname,
  tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('friendships', 'messages')
ORDER BY tablename;
