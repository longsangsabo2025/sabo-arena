-- ==========================================
-- SABO ARENA - SCALING INDEXES MIGRATION
-- Phase 1: Database Optimization for 100x Growth
-- ==========================================
--
-- OBJECTIVE: Create composite and optimized indexes for frequently queried columns
-- TARGET: Support 100K concurrent users with <100ms query times
-- EXECUTION: Use CONCURRENTLY to avoid locking tables
--
-- ==========================================

BEGIN;

-- ==========================================
-- COMPOSITE INDEXES FOR TOURNAMENTS
-- ==========================================

-- Tournament listings with status and time filtering (most common query)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournaments_status_start_time 
ON tournaments(status, start_time) 
WHERE status IN ('open', 'upcoming', 'in_progress');

-- Tournament search by club and status
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournaments_club_status 
ON tournaments(club_id, status) 
WHERE club_id IS NOT NULL;

-- Tournament public listings (for discovery)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournaments_public_status_start 
ON tournaments(is_public, status, start_time) 
WHERE is_public = true AND status IN ('open', 'upcoming');

-- ==========================================
-- COMPOSITE INDEXES FOR TOURNAMENT PARTICIPANTS
-- ==========================================

-- Participant lookups by tournament and user (most common)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournament_participants_tournament_user 
ON tournament_participants(tournament_id, user_id);

-- Participant status filtering by tournament
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournament_participants_tournament_status 
ON tournament_participants(tournament_id, status) 
WHERE status IN ('confirmed', 'pending');

-- ==========================================
-- COMPOSITE INDEXES FOR MATCHES
-- ==========================================

-- Match queries by tournament, round, and match number (bracket queries)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_tournament_round_match 
ON matches(tournament_id, round_number, match_number);

-- Match status filtering by tournament
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_tournament_status 
ON matches(tournament_id, status) 
WHERE status IN ('scheduled', 'in_progress', 'completed');

-- Match winner lookups
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_winner 
ON matches(winner_id) 
WHERE winner_id IS NOT NULL;

-- ==========================================
-- COMPOSITE INDEXES FOR CLUB MEMBERS
-- ==========================================

-- Club member lookups (most common query)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_club_members_club_user 
ON club_members(club_id, user_id);

-- Active club members by club
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_club_members_club_status 
ON club_members(club_id, status) 
WHERE status = 'active';

-- User's club memberships
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_club_members_user_status 
ON club_members(user_id, status) 
WHERE status = 'active';

-- ==========================================
-- COMPOSITE INDEXES FOR USER VOUCHERS
-- ==========================================

-- User voucher lookups with status and expiration
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_vouchers_user_status_expires 
ON user_vouchers(user_id, status, expires_at) 
WHERE status IN ('active', 'pending');

-- Voucher usage tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_vouchers_voucher_status 
ON user_vouchers(voucher_id, status);

-- ==========================================
-- COMPOSITE INDEXES FOR PAYMENTS
-- ==========================================

-- Payment history by user with status and date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payments_user_status_created 
ON payments(user_id, status, created_at DESC);

-- Payment status filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payments_status_created 
ON payments(status, created_at DESC) 
WHERE status IN ('pending', 'completed', 'failed');

-- ==========================================
-- COMPOSITE INDEXES FOR CHAT MESSAGES
-- ==========================================

-- Chat message pagination (room + time)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_messages_room_created 
ON chat_messages(room_id, created_at DESC);

-- Unread messages by user and room
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_messages_room_user_read 
ON chat_messages(room_id, user_id, is_read) 
WHERE is_read = false;

-- ==========================================
-- COMPOSITE INDEXES FOR PROFILES
-- ==========================================

-- Profile lookups by email (login queries)
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_profiles_email_unique 
ON profiles(email) 
WHERE email IS NOT NULL;

-- Profile lookups by username (search queries)
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_profiles_username_unique 
ON profiles(username) 
WHERE username IS NOT NULL;

-- Active user profiles
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_profiles_active_updated 
ON profiles(is_active, updated_at DESC) 
WHERE is_active = true;

-- ==========================================
-- COMPOSITE INDEXES FOR NOTIFICATIONS
-- ==========================================

-- Unread notifications by user
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_read_created 
ON notifications(user_id, is_read, created_at DESC) 
WHERE is_read = false;

-- Notification type filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_type_created 
ON notifications(user_id, notification_type, created_at DESC);

-- ==========================================
-- COMPOSITE INDEXES FOR POSTS
-- ==========================================

-- Post feed queries (user + time)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_user_created 
ON posts(user_id, created_at DESC);

-- Public post feed
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_public_created 
ON posts(is_public, created_at DESC) 
WHERE is_public = true;

-- Post likes count (for trending)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_likes_created 
ON posts(likes_count DESC, created_at DESC) 
WHERE likes_count > 0;

-- ==========================================
-- COMPOSITE INDEXES FOR CHALLENGES
-- ==========================================

-- Challenge lookups by challenger and status
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_challenges_challenger_status 
ON challenges(challenger_id, status);

-- Challenge lookups by challenged and status
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_challenges_challenged_status 
ON challenges(challenged_id, status);

-- Active challenges by club
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_challenges_club_status 
ON challenges(club_id, status) 
WHERE club_id IS NOT NULL AND status IN ('pending', 'accepted');

-- ==========================================
-- COMPOSITE INDEXES FOR TABLE RESERVATIONS
-- ==========================================

-- Reservations by club and date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_table_reservations_club_date 
ON table_reservations(club_id, reservation_date);

-- User reservations
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_table_reservations_user_status 
ON table_reservations(user_id, status, reservation_date DESC);

-- ==========================================
-- PARTIAL INDEXES FOR COMMON FILTERS
-- ==========================================

-- Active tournaments only
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournaments_active 
ON tournaments(start_time) 
WHERE status IN ('open', 'upcoming', 'in_progress') AND is_public = true;

-- Active users only
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_profiles_active_users 
ON profiles(updated_at DESC) 
WHERE is_active = true;

-- Pending payments
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payments_pending 
ON payments(created_at DESC) 
WHERE status = 'pending';

-- ==========================================
-- ANALYZE TABLES FOR QUERY PLANNER
-- ==========================================

ANALYZE tournaments;
ANALYZE tournament_participants;
ANALYZE matches;
ANALYZE club_members;
ANALYZE user_vouchers;
ANALYZE payments;
ANALYZE chat_messages;
ANALYZE profiles;
ANALYZE notifications;
ANALYZE posts;
ANALYZE challenges;
ANALYZE table_reservations;

COMMIT;

-- ==========================================
-- VERIFICATION QUERIES
-- ==========================================

-- Check index creation success
DO $$
DECLARE
    index_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%';
    
    RAISE NOTICE '========== SCALING INDEXES CREATED ==========';
    RAISE NOTICE 'Total scaling indexes: %', index_count;
    RAISE NOTICE '============================================';
END $$;

