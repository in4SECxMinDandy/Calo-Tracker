-- =============================================================================
-- Migration 031: Full-Text Search Optimization
-- =============================================================================
-- Purpose: Add full-text search capabilities for profiles, groups, posts, and foods
-- Date: 2026-02-12
-- Performance: PostgreSQL tsvector + GIN indexes for fast search
-- =============================================================================

-- =============================================================================
-- Add tsvector columns for search
-- =============================================================================

-- Profiles search
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Groups search
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Posts search
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- =============================================================================
-- Create GIN indexes for fast full-text search
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_search
ON public.profiles USING gin(search_vector);

CREATE INDEX IF NOT EXISTS idx_groups_search
ON public.groups USING gin(search_vector);

CREATE INDEX IF NOT EXISTS idx_posts_search
ON public.posts USING gin(search_vector);

-- =============================================================================
-- Functions to update search vectors
-- =============================================================================

-- Update profiles search vector
CREATE OR REPLACE FUNCTION update_profiles_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('simple',
    COALESCE(NEW.username, '') || ' ' ||
    COALESCE(NEW.display_name, '') || ' ' ||
    COALESCE(NEW.bio, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update groups search vector
CREATE OR REPLACE FUNCTION update_groups_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('simple',
    COALESCE(NEW.name, '') || ' ' ||
    COALESCE(NEW.description, '') || ' ' ||
    COALESCE(NEW.slug, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update posts search vector
CREATE OR REPLACE FUNCTION update_posts_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('simple',
    COALESCE(NEW.content, '') || ' ' ||
    COALESCE(NEW.location_name, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Create triggers for automatic search vector updates
-- =============================================================================

-- Profiles trigger
DROP TRIGGER IF EXISTS profiles_search_update ON public.profiles;
CREATE TRIGGER profiles_search_update
BEFORE INSERT OR UPDATE OF username, display_name, bio ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION update_profiles_search_vector();

-- Groups trigger
DROP TRIGGER IF EXISTS groups_search_update ON public.groups;
CREATE TRIGGER groups_search_update
BEFORE INSERT OR UPDATE OF name, description, slug ON public.groups
FOR EACH ROW
EXECUTE FUNCTION update_groups_search_vector();

-- Posts trigger
DROP TRIGGER IF EXISTS posts_search_update ON public.posts;
CREATE TRIGGER posts_search_update
BEFORE INSERT OR UPDATE OF content, location_name ON public.posts
FOR EACH ROW
EXECUTE FUNCTION update_posts_search_vector();

-- =============================================================================
-- Backfill existing data with search vectors
-- =============================================================================

-- Update profiles
UPDATE public.profiles
SET search_vector = to_tsvector('simple',
  COALESCE(username, '') || ' ' ||
  COALESCE(display_name, '') || ' ' ||
  COALESCE(bio, '')
)
WHERE search_vector IS NULL;

-- Update groups
UPDATE public.groups
SET search_vector = to_tsvector('simple',
  COALESCE(name, '') || ' ' ||
  COALESCE(description, '') || ' ' ||
  COALESCE(slug, '')
)
WHERE search_vector IS NULL;

-- Update posts
UPDATE public.posts
SET search_vector = to_tsvector('simple',
  COALESCE(content, '') || ' ' ||
  COALESCE(location_name, '')
)
WHERE search_vector IS NULL;

-- =============================================================================
-- Search helper functions
-- =============================================================================

-- Search profiles
CREATE OR REPLACE FUNCTION search_profiles(search_query TEXT, result_limit INTEGER DEFAULT 20)
RETURNS TABLE(
  id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.bio,
    ts_rank(p.search_vector, websearch_to_tsquery('simple', search_query)) AS rank
  FROM public.profiles p
  WHERE p.search_vector @@ websearch_to_tsquery('simple', search_query)
  AND NOT is_blocked(p.id) -- Exclude blocked users
  ORDER BY rank DESC, p.display_name ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search groups
CREATE OR REPLACE FUNCTION search_groups(search_query TEXT, result_limit INTEGER DEFAULT 20)
RETURNS TABLE(
  id UUID,
  name TEXT,
  slug TEXT,
  description TEXT,
  cover_image_url TEXT,
  category TEXT,
  member_count INTEGER,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    g.id,
    g.name,
    g.slug,
    g.description,
    g.cover_image_url,
    g.category,
    g.member_count,
    ts_rank(g.search_vector, websearch_to_tsquery('simple', search_query)) AS rank
  FROM public.groups g
  WHERE g.search_vector @@ websearch_to_tsquery('simple', search_query)
  AND (g.visibility = 'public' OR EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = g.id AND gm.user_id = auth.uid()
  ))
  ORDER BY rank DESC, g.member_count DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search posts
CREATE OR REPLACE FUNCTION search_posts(search_query TEXT, result_limit INTEGER DEFAULT 20)
RETURNS TABLE(
  id UUID,
  user_id UUID,
  content TEXT,
  image_urls TEXT[],
  like_count INTEGER,
  comment_count INTEGER,
  created_at TIMESTAMPTZ,
  author_username TEXT,
  author_display_name TEXT,
  author_avatar_url TEXT,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.user_id,
    p.content,
    p.image_urls,
    p.like_count,
    p.comment_count,
    p.created_at,
    prof.username AS author_username,
    prof.display_name AS author_display_name,
    prof.avatar_url AS author_avatar_url,
    ts_rank(p.search_vector, websearch_to_tsquery('simple', search_query)) AS rank
  FROM public.posts p
  INNER JOIN public.profiles prof ON p.user_id = prof.id
  WHERE p.search_vector @@ websearch_to_tsquery('simple', search_query)
  AND p.visibility = 'public'
  AND p.is_hidden = false
  AND NOT is_blocked(p.user_id)
  ORDER BY rank DESC, p.created_at DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Global search (all content types)
CREATE OR REPLACE FUNCTION global_search(
  search_query TEXT,
  search_type TEXT DEFAULT 'all', -- 'all', 'users', 'groups', 'posts'
  result_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
  result_type TEXT,
  result_id UUID,
  title TEXT,
  subtitle TEXT,
  image_url TEXT,
  rank REAL
) AS $$
BEGIN
  IF search_type IN ('all', 'users') THEN
    RETURN QUERY
    SELECT
      'user'::TEXT AS result_type,
      p.id AS result_id,
      p.display_name AS title,
      '@' || p.username AS subtitle,
      p.avatar_url AS image_url,
      ts_rank(p.search_vector, websearch_to_tsquery('simple', search_query)) AS rank
    FROM public.profiles p
    WHERE p.search_vector @@ websearch_to_tsquery('simple', search_query)
    AND NOT is_blocked(p.id)
    ORDER BY rank DESC
    LIMIT result_limit;
  END IF;

  IF search_type IN ('all', 'groups') THEN
    RETURN QUERY
    SELECT
      'group'::TEXT AS result_type,
      g.id AS result_id,
      g.name AS title,
      g.member_count || ' thành viên' AS subtitle,
      g.cover_image_url AS image_url,
      ts_rank(g.search_vector, websearch_to_tsquery('simple', search_query)) AS rank
    FROM public.groups g
    WHERE g.search_vector @@ websearch_to_tsquery('simple', search_query)
    AND g.visibility = 'public'
    ORDER BY rank DESC
    LIMIT result_limit;
  END IF;

  IF search_type IN ('all', 'posts') THEN
    RETURN QUERY
    SELECT
      'post'::TEXT AS result_type,
      p.id AS result_id,
      LEFT(p.content, 100) AS title,
      prof.display_name || ' • ' || to_char(p.created_at, 'DD/MM/YYYY') AS subtitle,
      prof.avatar_url AS image_url,
      ts_rank(p.search_vector, websearch_to_tsquery('simple', search_query)) AS rank
    FROM public.posts p
    INNER JOIN public.profiles prof ON p.user_id = prof.id
    WHERE p.search_vector @@ websearch_to_tsquery('simple', search_query)
    AND p.visibility = 'public'
    AND p.is_hidden = false
    AND NOT is_blocked(p.user_id)
    ORDER BY rank DESC
    LIMIT result_limit;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- Search history table (optional, for analytics and suggestions)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.search_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  search_query TEXT NOT NULL,
  search_type TEXT,
  results_count INTEGER,
  clicked_result_id UUID,
  clicked_result_type TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_search_history_user ON public.search_history(user_id, created_at DESC);
CREATE INDEX idx_search_history_query ON public.search_history(search_query);

-- RLS for search history
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own search history"
ON public.search_history FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Function to get popular searches (trending)
CREATE OR REPLACE FUNCTION get_trending_searches(result_limit INTEGER DEFAULT 10)
RETURNS TABLE(
  search_query TEXT,
  search_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    sh.search_query,
    COUNT(*) AS search_count
  FROM public.search_history sh
  WHERE sh.created_at > NOW() - INTERVAL '7 days'
  GROUP BY sh.search_query
  ORDER BY search_count DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- Comments
-- =============================================================================
COMMENT ON COLUMN public.profiles.search_vector IS 'Full-text search vector for username, display_name, bio';
COMMENT ON COLUMN public.groups.search_vector IS 'Full-text search vector for name, description, slug';
COMMENT ON COLUMN public.posts.search_vector IS 'Full-text search vector for content, location_name';
COMMENT ON FUNCTION global_search(TEXT, TEXT, INTEGER) IS 'Search across users, groups, and posts with unified results';
COMMENT ON FUNCTION get_trending_searches(INTEGER) IS 'Get most popular search queries from last 7 days';
COMMENT ON TABLE public.search_history IS 'User search history for analytics and personalized suggestions';
