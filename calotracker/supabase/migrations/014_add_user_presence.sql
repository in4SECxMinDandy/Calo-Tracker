-- ===================================================================
-- User Presence System (Online Status - Facebook-like)
-- ===================================================================

-- Create user_presence table
CREATE TABLE IF NOT EXISTS public.user_presence (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;

-- Anyone can view presence (for friends to see online status)
DROP POLICY IF EXISTS "Anyone can view presence" ON public.user_presence;
CREATE POLICY "Anyone can view presence"
ON public.user_presence FOR SELECT
USING (true);

-- Users can only update their own presence
DROP POLICY IF EXISTS "Users can update own presence" ON public.user_presence;
CREATE POLICY "Users can update own presence"
ON public.user_presence FOR ALL
USING (auth.uid() = user_id);

-- Create index for quick lookups
CREATE INDEX IF NOT EXISTS idx_user_presence_online
ON public.user_presence (is_online);

-- Trigger to auto-update updated_at
CREATE TRIGGER update_user_presence_updated_at
BEFORE UPDATE ON public.user_presence
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Function to set user online
CREATE OR REPLACE FUNCTION public.set_user_online(p_user_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO public.user_presence (user_id, is_online, last_seen)
  VALUES (p_user_id, true, NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET
    is_online = true,
    last_seen = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to set user offline
CREATE OR REPLACE FUNCTION public.set_user_offline(p_user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.user_presence
  SET is_online = false, last_seen = NOW()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- DONE! User presence system ready
-- ===================================================================
