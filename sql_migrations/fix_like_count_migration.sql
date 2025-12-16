-- Fix Like Count Display Bug Migration
-- Issue: App uses post_interactions table but some data may be in post_likes table
-- Solution: Migrate all data to post_interactions and update triggers

-- 🔍 Check current state
SELECT 'post_likes count' as table_name, COUNT(*) as records FROM post_likes
UNION ALL
SELECT 'post_interactions likes count' as table_name, COUNT(*) as records 
FROM post_interactions WHERE interaction_type = 'like';

-- 🚀 STEP 1: Migrate data from post_likes to post_interactions
INSERT INTO post_interactions (post_id, user_id, interaction_type, created_at)
SELECT 
    pl.post_id,
    pl.user_id,
    'like' as interaction_type,
    COALESCE(pl.created_at, NOW()) as created_at
FROM post_likes pl
WHERE NOT EXISTS (
    -- Avoid duplicates
    SELECT 1 FROM post_interactions pi 
    WHERE pi.post_id = pl.post_id 
    AND pi.user_id = pl.user_id 
    AND pi.interaction_type = 'like'
);

-- 🔄 STEP 2: Recalculate like_count for all posts
UPDATE posts 
SET like_count = (
    SELECT COUNT(*) 
    FROM post_interactions 
    WHERE post_id = posts.id 
    AND interaction_type = 'like'
);

-- 🧹 STEP 3: Clean up old post_likes table (optional - backup first!)
-- TRUNCATE TABLE post_likes; -- Uncomment when ready to clean up

-- 📊 STEP 4: Verify the fix
SELECT 
    p.id,
    p.like_count as stored_count,
    COUNT(pi.id) as actual_count,
    CASE 
        WHEN p.like_count = COUNT(pi.id) THEN '✅ Correct'
        ELSE '❌ Mismatch'
    END as status
FROM posts p
LEFT JOIN post_interactions pi ON p.id = pi.post_id AND pi.interaction_type = 'like'
GROUP BY p.id, p.like_count
HAVING p.like_count != COUNT(pi.id)
ORDER BY p.created_at DESC
LIMIT 10;

-- 🎯 STEP 5: Create/Update triggers to maintain consistency
CREATE OR REPLACE FUNCTION update_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.interaction_type = 'like' THEN
        UPDATE posts 
        SET like_count = like_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' AND OLD.interaction_type = 'like' THEN
        UPDATE posts 
        SET like_count = GREATEST(like_count - 1, 0) 
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_update_like_count_insert ON post_interactions;
DROP TRIGGER IF EXISTS trigger_update_like_count_delete ON post_interactions;

CREATE TRIGGER trigger_update_like_count_insert
    AFTER INSERT ON post_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_post_like_count();

CREATE TRIGGER trigger_update_like_count_delete
    AFTER DELETE ON post_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_post_like_count();

-- 📈 FINAL CHECK: Show post with most likes for verification
SELECT 
    p.id,
    p.content,
    p.like_count,
    COUNT(pi.id) as actual_likes,
    array_agg(u.display_name) as liked_by
FROM posts p
LEFT JOIN post_interactions pi ON p.id = pi.post_id AND pi.interaction_type = 'like'
LEFT JOIN users u ON pi.user_id = u.id
GROUP BY p.id, p.content, p.like_count
ORDER BY p.like_count DESC
LIMIT 5;