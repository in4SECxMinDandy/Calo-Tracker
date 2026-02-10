-- Migration 017: Fix missing profiles + member count trigger
-- Root cause: handle_new_user trigger may have failed, leaving users without profiles
-- Also: member_count on groups never gets updated

-- ===================================================================
-- PART 1: FIX MISSING PROFILES
-- ===================================================================

-- Create profiles for ALL existing auth users who don't have one
INSERT INTO public.profiles (id, username, display_name)
SELECT
  u.id,
  COALESCE(u.raw_user_meta_data->>'username', 'user_' || substr(u.id::text, 1, 8)),
  COALESCE(
    u.raw_user_meta_data->>'display_name',
    u.raw_user_meta_data->>'full_name',
    u.email,
    'Người dùng mới'
  )
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Recreate the trigger function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      'user_' || substr(NEW.id::text, 1, 8)
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      'Người dùng mới'
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;

  BEGIN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'user')
    ON CONFLICT DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ===================================================================
-- PART 2: FIX GROUP MEMBER COUNT
-- ===================================================================

-- Trigger function: update member_count when members are added/removed
CREATE OR REPLACE FUNCTION public.update_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.groups
    SET member_count = (
      SELECT count(*) FROM public.group_members
      WHERE group_id = NEW.group_id AND status = 'active'
    )
    WHERE id = NEW.group_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.groups
    SET member_count = (
      SELECT count(*) FROM public.group_members
      WHERE group_id = OLD.group_id AND status = 'active'
    )
    WHERE id = OLD.group_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- When status changes (e.g. pending -> active)
    UPDATE public.groups
    SET member_count = (
      SELECT count(*) FROM public.group_members
      WHERE group_id = NEW.group_id AND status = 'active'
    )
    WHERE id = NEW.group_id;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on group_members
DROP TRIGGER IF EXISTS on_group_member_change ON public.group_members;
CREATE TRIGGER on_group_member_change
  AFTER INSERT OR UPDATE OR DELETE ON public.group_members
  FOR EACH ROW
  EXECUTE FUNCTION public.update_group_member_count();

-- Fix existing groups: sync member_count with actual count
UPDATE public.groups g
SET member_count = (
  SELECT count(*) FROM public.group_members gm
  WHERE gm.group_id = g.id AND gm.status = 'active'
);

-- ===================================================================
-- PART 3: VERIFY
-- ===================================================================

SELECT 'Users without profiles:' as check_name, count(*) as count
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

SELECT 'Groups member count check:' as check_name,
  g.name, g.member_count,
  (SELECT count(*) FROM group_members gm WHERE gm.group_id = g.id AND gm.status = 'active') as actual_count
FROM groups g;
