
-- Quick Like Count Fix
-- Run this in Supabase SQL Editor

-- 1. Check current state
SELECT 
    'post_likes' as table_name, 
    COUNT(*) as count 
FROM post_likes
UNION ALL
SELECT 
    'post_interactions (likes)' as table_name, 
    COUNT(*) as count 
FROM post_interactions 
WHERE interaction_type = 'like';

-- 2. Migrate missing data from post_likes to post_interactions
INSERT INTO post_interactions (post_id, user_id, interaction_type, created_at)
SELECT 
    pl.post_id,
    pl.user_id,
    'like' as interaction_type,
    COALESCE(pl.created_at, NOW()) as created_at
FROM post_likes pl
WHERE NOT EXISTS (
    SELECT 1 FROM post_interactions pi 
    WHERE pi.post_id = pl.post_id 
    AND pi.user_id = pl.user_id 
    AND pi.interaction_type = 'like'
);

-- 3. Recalculate like_count for all posts
UPDATE posts 
SET like_count = (
    SELECT COUNT(*) 
    FROM post_interactions 
    WHERE post_id = posts.id 
    AND interaction_type = 'like'
);

-- 4. Verify fix (show posts with potential issues)
SELECT 
    p.id,
    p.like_count as stored_count,
    COUNT(pi.id) as actual_count,
    CASE 
        WHEN p.like_count = COUNT(pi.id) THEN '✅ OK'
        ELSE '❌ MISMATCH'
    END as status
FROM posts p
LEFT JOIN post_interactions pi ON p.id = pi.post_id AND pi.interaction_type = 'like'
GROUP BY p.id, p.like_count
ORDER BY p.created_at DESC
LIMIT 10;
