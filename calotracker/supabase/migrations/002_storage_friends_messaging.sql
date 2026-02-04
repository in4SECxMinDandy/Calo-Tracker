-- =============================================================================
-- CaloTracker - Storage, Friends & Messaging Migration
-- =============================================================================
-- Run this script in Supabase Dashboard > SQL Editor
-- Version: 2.0.0
-- Date: 2026-02-03
-- =============================================================================

-- ============================================
-- PART 1: STORAGE BUCKETS
-- ============================================

-- Create buckets for avatars and post images
INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('avatars', 'avatars', true), 
  ('post-images', 'post-images', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- PART 2: STORAGE POLICIES
-- ============================================

-- Avatars bucket policies
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Post images bucket policies
DROP POLICY IF EXISTS "Post images are publicly accessible" ON storage.objects;
CREATE POLICY "Post images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'post-images');

DROP POLICY IF EXISTS "Users can upload post images" ON storage.objects;
CREATE POLICY "Users can upload post images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete their own post images" ON storage.objects;
CREATE POLICY "Users can delete their own post images" ON storage.objects
  FOR DELETE USING (bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================
-- PART 3: PROFILES UPDATE (Online Status)
-- ============================================

-- Add online status columns to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ;

-- ============================================
-- PART 4: FRIENDSHIPS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

CREATE INDEX IF NOT EXISTS idx_friendships_user ON public.friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend ON public.friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

-- Friendships RLS
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own friendships" ON public.friendships;
CREATE POLICY "Users can view their own friendships" ON public.friendships
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
CREATE POLICY "Users can send friend requests" ON public.friendships
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own friendships" ON public.friendships;
CREATE POLICY "Users can update their own friendships" ON public.friendships
  FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS "Users can delete their own friendships" ON public.friendships;
CREATE POLICY "Users can delete their own friendships" ON public.friendships
  FOR DELETE USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- ============================================
-- PART 5: MESSAGES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (sender_id != receiver_id)
);

CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(sender_id, receiver_id, created_at DESC);

-- Messages RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own messages" ON public.messages;
CREATE POLICY "Users can view their own messages" ON public.messages
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can mark messages as read" ON public.messages;
CREATE POLICY "Users can mark messages as read" ON public.messages
  FOR UPDATE USING (auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can delete their own sent messages" ON public.messages;
CREATE POLICY "Users can delete their own sent messages" ON public.messages
  FOR DELETE USING (auth.uid() = sender_id);

-- ============================================
-- PART 6: HELPER FUNCTIONS
-- ============================================

-- Function to update online status
CREATE OR REPLACE FUNCTION public.update_user_online_status(is_online_status BOOLEAN)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET 
    is_online = is_online_status,
    last_seen = CASE WHEN is_online_status = false THEN NOW() ELSE last_seen END
  WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get friends list with online status
CREATE OR REPLACE FUNCTION public.get_friends_with_status()
RETURNS TABLE (
  friendship_id UUID,
  friend_id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  is_online BOOLEAN,
  last_seen TIMESTAMPTZ,
  friendship_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    f.id as friendship_id,
    CASE WHEN f.user_id = auth.uid() THEN f.friend_id ELSE f.user_id END as friend_id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.is_online,
    p.last_seen,
    f.status as friendship_status
  FROM public.friendships f
  JOIN public.profiles p ON p.id = CASE 
    WHEN f.user_id = auth.uid() THEN f.friend_id 
    ELSE f.user_id 
  END
  WHERE (f.user_id = auth.uid() OR f.friend_id = auth.uid())
    AND f.status = 'accepted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get conversation messages
CREATE OR REPLACE FUNCTION public.get_conversation(other_user_id UUID, msg_limit INT DEFAULT 50)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  receiver_id UUID,
  content TEXT,
  is_read BOOLEAN,
  created_at TIMESTAMPTZ,
  is_mine BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.sender_id,
    m.receiver_id,
    m.content,
    m.is_read,
    m.created_at,
    m.sender_id = auth.uid() as is_mine
  FROM public.messages m
  WHERE (m.sender_id = auth.uid() AND m.receiver_id = other_user_id)
     OR (m.sender_id = other_user_id AND m.receiver_id = auth.uid())
  ORDER BY m.created_at DESC
  LIMIT msg_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- DONE!
-- ============================================

COMMENT ON TABLE public.friendships IS 'Friend relationships between users';
COMMENT ON TABLE public.messages IS 'Private messages between users';
