-- ===================================================================
-- Add location fields to posts table
-- ===================================================================

-- Add location columns
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS location_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_lng DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_name TEXT;

-- Create index for location queries (optional, for future features)
CREATE INDEX IF NOT EXISTS posts_location_idx
ON public.posts (location_lat, location_lng)
WHERE location_lat IS NOT NULL AND location_lng IS NOT NULL;

-- ===================================================================
-- DONE! Posts can now store location data
-- ===================================================================
