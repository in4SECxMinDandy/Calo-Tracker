-- ===================================================================
-- Add updated_at trigger for friendships table
-- ===================================================================

-- Apply updated_at trigger to friendships
CREATE TRIGGER update_friendships_updated_at
BEFORE UPDATE ON public.friendships
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ===================================================================
-- DONE! Friendships updated_at will auto-update on changes
-- ===================================================================
