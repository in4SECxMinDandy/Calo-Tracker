-- ===================================================================
-- FIX: Update group creators to have owner role
-- Problem: Some group creators have role='member' instead of 'owner'
-- ===================================================================

-- Update all group creators to have owner role
UPDATE public.group_members gm
SET role = 'owner'
FROM public.groups g
WHERE gm.group_id = g.id
  AND gm.user_id = g.created_by
  AND gm.role != 'owner';

-- ===================================================================
-- DONE! All group creators now have owner role
-- ===================================================================
