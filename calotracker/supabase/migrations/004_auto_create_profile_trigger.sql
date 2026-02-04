-- =============================================================================
-- CaloTracker - Auto Create Profile Trigger
-- =============================================================================
-- Run this script in Supabase Dashboard > SQL Editor
-- This automatically creates a profile when a user signs up via OAuth or Email
-- =============================================================================

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  generated_username TEXT;
  base_username TEXT;
  counter INTEGER := 0;
BEGIN
  -- Extract base username from email (before @) or use 'user'
  IF NEW.email IS NOT NULL THEN
    base_username := split_part(NEW.email, '@', 1);
  ELSE
    base_username := 'user';
  END IF;

  -- Remove special characters and make lowercase
  base_username := lower(regexp_replace(base_username, '[^a-zA-Z0-9]', '', 'g'));
  
  -- Ensure username is at least 3 characters
  IF length(base_username) < 3 THEN
    base_username := 'user' || base_username;
  END IF;

  generated_username := base_username;

  -- Find unique username by appending numbers if needed
  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = generated_username) LOOP
    counter := counter + 1;
    generated_username := base_username || counter::TEXT;
  END LOOP;

  -- Insert new profile
  INSERT INTO public.profiles (
    id,
    username,
    display_name,
    avatar_url,
    bio,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    generated_username,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', generated_username),
    NEW.raw_user_meta_data->>'avatar_url',
    NULL,
    NOW(),
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- DONE! Now profiles will be automatically created on signup/OAuth
-- =============================================================================

COMMENT ON FUNCTION public.handle_new_user() IS 'Automatically creates a profile for new auth users';
