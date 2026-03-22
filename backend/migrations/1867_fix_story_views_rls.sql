-- Fix story_views RLS: restrict reads to story owners only
-- Previously all authenticated users could see who viewed anyone's story.

DROP POLICY IF EXISTS "Authenticated users can view story_views" ON public.story_views;

CREATE POLICY "Story owners can view story_views" ON public.story_views
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stories s
            WHERE s.id = story_views.story_id
            AND s.user_id IN (SELECT id FROM users WHERE auth_id = (select auth.uid()))
        )
    );
