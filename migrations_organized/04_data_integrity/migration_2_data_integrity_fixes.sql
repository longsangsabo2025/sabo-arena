-- ==========================================
-- SABO ARENA - DATA INTEGRITY FIXES
-- EXECUTE AFTER CRITICAL SECURITY FIXES  
-- ==========================================
--
-- ⚠️  WARNING: This script adds critical data integrity constraints
-- 🎯 OBJECTIVE: Ensure referential integrity and prevent data corruption
-- ⏱️  DURATION: ~30 minutes execution time
-- 📋 PREREQUISITE: Execute security fixes first, test in staging
--
-- Data Integrity Issues:
-- - Missing foreign key constraints (orphaned records possible)
-- - Missing unique constraints (duplicate data possible)
-- - No referential integrity enforcement
-- - Data consistency not guaranteed
--
-- ==========================================

BEGIN;

-- ==========================================
-- STEP 1: ADD FOREIGN KEY CONSTRAINTS
-- ==========================================

-- TOURNAMENT SYSTEM RELATIONSHIPS
-- tournaments.organizer_id → users.id
ALTER TABLE tournaments 
ADD CONSTRAINT fk_tournaments_organizer_id 
FOREIGN KEY (organizer_id) REFERENCES users(id) ON DELETE CASCADE;

-- tournaments.club_id → clubs.id  
ALTER TABLE tournaments 
ADD CONSTRAINT fk_tournaments_club_id 
FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE;

-- tournament_participants.tournament_id → tournaments.id
ALTER TABLE tournament_participants 
ADD CONSTRAINT fk_tournament_participants_tournament_id 
FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE;

-- tournament_participants.user_id → users.id
ALTER TABLE tournament_participants 
ADD CONSTRAINT fk_tournament_participants_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- tournament_payments.tournament_id → tournaments.id
ALTER TABLE tournament_payments 
ADD CONSTRAINT fk_tournament_payments_tournament_id 
FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE;

-- tournament_payments.user_id → users.id
ALTER TABLE tournament_payments 
ADD CONSTRAINT fk_tournament_payments_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- CLUB SYSTEM RELATIONSHIPS
-- club_members.club_id → clubs.id
ALTER TABLE club_members 
ADD CONSTRAINT fk_club_members_club_id 
FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE;

-- club_members.user_id → users.id  
ALTER TABLE club_members 
ADD CONSTRAINT fk_club_members_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- club_follows.club_id → clubs.id
ALTER TABLE club_follows 
ADD CONSTRAINT fk_club_follows_club_id 
FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE;

-- club_follows.user_id → users.id
ALTER TABLE club_follows 
ADD CONSTRAINT fk_club_follows_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- club_reviews.club_id → clubs.id
ALTER TABLE club_reviews 
ADD CONSTRAINT fk_club_reviews_club_id 
FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE;

-- club_reviews.user_id → users.id
ALTER TABLE club_reviews 
ADD CONSTRAINT fk_club_reviews_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- SOCIAL FEATURES RELATIONSHIPS  
-- posts.user_id → users.id
ALTER TABLE posts 
ADD CONSTRAINT fk_posts_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- post_comments.post_id → posts.id
ALTER TABLE post_comments 
ADD CONSTRAINT fk_post_comments_post_id 
FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;

-- post_comments.user_id → users.id
ALTER TABLE post_comments 
ADD CONSTRAINT fk_post_comments_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- post_likes.post_id → posts.id
ALTER TABLE post_likes 
ADD CONSTRAINT fk_post_likes_post_id 
FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;

-- post_likes.user_id → users.id
ALTER TABLE post_likes 
ADD CONSTRAINT fk_post_likes_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- user_follows.follower_id → users.id
ALTER TABLE user_follows 
ADD CONSTRAINT fk_user_follows_follower_id 
FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE;

-- user_follows.following_id → users.id
ALTER TABLE user_follows 
ADD CONSTRAINT fk_user_follows_following_id 
FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE;

-- CHAT SYSTEM RELATIONSHIPS
-- chat_messages.room_id → chat_rooms.id
ALTER TABLE chat_messages 
ADD CONSTRAINT fk_chat_messages_room_id 
FOREIGN KEY (room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE;

-- chat_messages.user_id → users.id
ALTER TABLE chat_messages 
ADD CONSTRAINT fk_chat_messages_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- chat_room_members.room_id → chat_rooms.id
ALTER TABLE chat_room_members 
ADD CONSTRAINT fk_chat_room_members_room_id 
FOREIGN KEY (room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE;

-- chat_room_members.user_id → users.id
ALTER TABLE chat_room_members 
ADD CONSTRAINT fk_chat_room_members_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- PAYMENT SYSTEM RELATIONSHIPS
-- payments.user_id → users.id
ALTER TABLE payments 
ADD CONSTRAINT fk_payments_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- user_vouchers.user_id → users.id
ALTER TABLE user_vouchers 
ADD CONSTRAINT fk_user_vouchers_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- user_vouchers.voucher_id → voucher_templates.id (if voucher_id references voucher_templates)
-- Note: Uncomment if this relationship exists
-- ALTER TABLE user_vouchers 
-- ADD CONSTRAINT fk_user_vouchers_voucher_id 
-- FOREIGN KEY (voucher_id) REFERENCES voucher_templates(id) ON DELETE CASCADE;

-- ACHIEVEMENT SYSTEM RELATIONSHIPS
-- user_achievements.user_id → users.id
ALTER TABLE user_achievements 
ADD CONSTRAINT fk_user_achievements_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- user_achievements.achievement_id → achievements.id
ALTER TABLE user_achievements 
ADD CONSTRAINT fk_user_achievements_achievement_id 
FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE;

-- RANKING SYSTEM RELATIONSHIPS
-- ranked_users.user_id → users.id
ALTER TABLE ranked_users 
ADD CONSTRAINT fk_ranked_users_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- rank_change_logs.user_id → users.id
ALTER TABLE rank_change_logs 
ADD CONSTRAINT fk_rank_change_logs_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- MATCH SYSTEM RELATIONSHIPS
-- matches.tournament_id → tournaments.id
ALTER TABLE matches 
ADD CONSTRAINT fk_matches_tournament_id 
FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE;

-- ==========================================
-- STEP 2: ADD UNIQUE CONSTRAINTS
-- ==========================================

-- USER SYSTEM UNIQUE CONSTRAINTS
-- Prevent duplicate emails
ALTER TABLE users ADD CONSTRAINT unique_users_email UNIQUE(email);

-- Prevent duplicate usernames
ALTER TABLE users ADD CONSTRAINT unique_users_username UNIQUE(username);

-- CLUB SYSTEM UNIQUE CONSTRAINTS  
-- Prevent duplicate club names (if desired)
-- ALTER TABLE clubs ADD CONSTRAINT unique_clubs_name UNIQUE(name);

-- VOUCHER SYSTEM UNIQUE CONSTRAINTS
-- Prevent duplicate voucher codes
ALTER TABLE voucher_templates ADD CONSTRAINT unique_voucher_templates_code UNIQUE(code);

-- Prevent duplicate referral codes
ALTER TABLE referral_codes ADD CONSTRAINT unique_referral_codes_code UNIQUE(code);

-- SOCIAL SYSTEM UNIQUE CONSTRAINTS
-- Prevent duplicate follows (user can't follow same person twice)
ALTER TABLE user_follows ADD CONSTRAINT unique_user_follows 
UNIQUE(follower_id, following_id);

-- Prevent duplicate club follows
ALTER TABLE club_follows ADD CONSTRAINT unique_club_follows 
UNIQUE(user_id, club_id);

-- Prevent duplicate likes on same post
ALTER TABLE post_likes ADD CONSTRAINT unique_post_likes 
UNIQUE(user_id, post_id);

-- TOURNAMENT SYSTEM UNIQUE CONSTRAINTS
-- Prevent duplicate tournament participations
ALTER TABLE tournament_participants ADD CONSTRAINT unique_tournament_participants 
UNIQUE(tournament_id, user_id);

-- ==========================================
-- STEP 3: ADD CHECK CONSTRAINTS (Data Validation)
-- ==========================================

-- USER SYSTEM VALIDATION
-- Ensure valid email format (basic check)
ALTER TABLE users ADD CONSTRAINT check_users_email_format 
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- TOURNAMENT SYSTEM VALIDATION
-- Ensure positive entry fees
ALTER TABLE tournaments ADD CONSTRAINT check_tournaments_entry_fee_positive 
CHECK (entry_fee >= 0);

-- Ensure positive prize pool
ALTER TABLE tournaments ADD CONSTRAINT check_tournaments_prize_pool_positive 
CHECK (prize_pool >= 0);

-- Ensure max participants is positive
ALTER TABLE tournaments ADD CONSTRAINT check_tournaments_max_participants_positive 
CHECK (max_participants > 0);

-- Ensure current participants doesn't exceed max
ALTER TABLE tournaments ADD CONSTRAINT check_tournaments_participants_limit 
CHECK (current_participants <= max_participants);

-- Ensure valid status values
ALTER TABLE tournaments ADD CONSTRAINT check_tournaments_status_valid 
CHECK (status IN ('draft', 'open', 'active', 'completed', 'cancelled'));

-- PAYMENT SYSTEM VALIDATION
-- Ensure positive payment amounts
ALTER TABLE payments ADD CONSTRAINT check_payments_amount_positive 
CHECK (amount >= 0);

-- Ensure valid payment status
ALTER TABLE payments ADD CONSTRAINT check_payments_status_valid 
CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled'));

-- ==========================================
-- STEP 4: CREATE INDEXES FOR FOREIGN KEYS
-- ==========================================

-- Create indexes on foreign key columns for better performance
-- Note: Some of these indexes might already exist

-- Tournament system indexes
CREATE INDEX IF NOT EXISTS idx_tournaments_organizer_id ON tournaments(organizer_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_club_id ON tournaments(club_id);
CREATE INDEX IF NOT EXISTS idx_tournament_participants_tournament_id ON tournament_participants(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_participants_user_id ON tournament_participants(user_id);

-- Club system indexes  
CREATE INDEX IF NOT EXISTS idx_club_members_club_id ON club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_club_members_user_id ON club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_club_follows_club_id ON club_follows(club_id);
CREATE INDEX IF NOT EXISTS idx_club_follows_user_id ON club_follows(user_id);

-- Social system indexes
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_user_id ON post_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);

-- Chat system indexes
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);

-- Payment system indexes
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_vouchers_user_id ON user_vouchers(user_id);

-- ==========================================
-- STEP 5: VERIFICATION QUERIES
-- ==========================================

-- Check foreign key constraints
DO $$
DECLARE
    fk_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints
    WHERE constraint_type = 'FOREIGN KEY'
    AND table_schema = 'public';
    
    RAISE NOTICE '========== FOREIGN KEYS VERIFICATION ==========';
    RAISE NOTICE 'Total foreign key constraints: %', fk_count;
    RAISE NOTICE '===============================================';
END $$;

-- Check unique constraints
DO $$
DECLARE
    unique_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO unique_count
    FROM information_schema.table_constraints
    WHERE constraint_type = 'UNIQUE'
    AND table_schema = 'public';
    
    RAISE NOTICE '========== UNIQUE CONSTRAINTS VERIFICATION ==========';
    RAISE NOTICE 'Total unique constraints: %', unique_count;
    RAISE NOTICE '====================================================';
END $$;

-- ==========================================
-- COMMIT TRANSACTION
-- ==========================================

COMMIT;

-- ==========================================
-- POST-EXECUTION VERIFICATION QUERIES
-- ==========================================

/*
-- Run these queries AFTER executing the script to verify integrity:

-- 1. List all foreign key constraints
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- 2. List all unique constraints
SELECT
    tc.table_name,
    kcu.column_name,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'UNIQUE'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- 3. Check for orphaned records (should return 0 for all)
SELECT 'tournaments with invalid organizer_id' as check_name, COUNT(*) as orphaned_count
FROM tournaments t
LEFT JOIN users u ON t.organizer_id = u.id
WHERE u.id IS NULL AND t.organizer_id IS NOT NULL

UNION ALL

SELECT 'tournament_participants with invalid tournament_id', COUNT(*)
FROM tournament_participants tp
LEFT JOIN tournaments t ON tp.tournament_id = t.id
WHERE t.id IS NULL AND tp.tournament_id IS NOT NULL

UNION ALL

SELECT 'club_members with invalid club_id', COUNT(*)
FROM club_members cm
LEFT JOIN clubs c ON cm.club_id = c.id
WHERE c.id IS NULL AND cm.club_id IS NOT NULL;

-- 4. Test constraint violations (these should fail)
-- INSERT INTO tournaments (id, organizer_id) VALUES ('test', 'nonexistent-user-id');
-- INSERT INTO users (email) VALUES ('invalid-email');
*/

-- ==========================================
-- CRITICAL NOTES
-- ==========================================

/*
🚨 IMPORTANT POST-EXECUTION STEPS:

1. VERIFY DATA INTEGRITY:
   - Run the verification queries above
   - Check for any orphaned records
   - Verify constraints are working

2. TEST APPLICATION:
   - Test all CRUD operations
   - Verify foreign key relationships work
   - Check that invalid data is rejected

3. MONITOR FOR ISSUES:
   - Watch for constraint violation errors
   - Check application logs for database errors
   - Verify data operations still work

4. NEXT STEPS:
   - Execute performance optimization script
   - Set up monitoring and alerting
   - Plan for production deployment

⚠️ ROLLBACK PLAN (if critical issues):
   - Drop constraints: ALTER TABLE tablename DROP CONSTRAINT constraintname;
   - Remove unique constraints if causing issues
   - Re-add constraints after fixing data issues

🔒 Data Integrity Status After This Script:
   ✅ Foreign key constraints enforced
   ✅ Unique constraints prevent duplicates
   ✅ Check constraints validate data
   ✅ Orphaned records prevention
   ✅ Referential integrity guaranteed

📈 Performance Impact:
   ⚠️ Initial execution may be slow (adding constraints)
   ✅ Long-term performance improved with indexes
   ✅ Data operations more reliable
   ✅ Query optimization possible with guaranteed relationships
*/