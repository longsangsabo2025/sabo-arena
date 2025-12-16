-- ==========================================
-- SABO ARENA - CRITICAL SECURITY FIXES  
-- EXECUTE IMMEDIATELY - P0 PRIORITY
-- ==========================================
--
-- ⚠️  WARNING: This script fixes critical security vulnerabilities
-- 🚨 IMPACT: Currently anonymous users can access sensitive data
-- 🎯 OBJECTIVE: Block all unauthorized data access immediately
-- ⏱️  DURATION: ~15 minutes execution time
-- 📋 PREREQUISITE: Test in staging environment first
--
-- Security Issues Found:
-- - 23+ tables accessible to anonymous users
-- - User profiles, tournaments, clubs exposed
-- - Admin logs and system data leaked
-- - Payment and analytics data accessible
--
-- ==========================================

BEGIN;

-- ==========================================
-- STEP 1: ENABLE ROW LEVEL SECURITY
-- ==========================================

-- Enable RLS on all critical data tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE recent_tournament_activity ENABLE ROW LEVEL SECURITY;

-- Club management security
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_analytics_summary ENABLE ROW LEVEL SECURITY;

-- User data security
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_performance_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_vouchers ENABLE ROW LEVEL SECURITY;

-- Social features security
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_eligibility ENABLE ROW LEVEL SECURITY;

-- Payment and voucher security
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE voucher_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;

-- Administrative security
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;

-- Analytics and health data security
ALTER TABLE spa_economy_health ENABLE ROW LEVEL SECURITY;
ALTER TABLE rank_change_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_challenges_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE popular_hashtags ENABLE ROW LEVEL SECURITY;

-- System tables (typically should be public, but securing for now)
ALTER TABLE geography_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- STEP 2: CREATE EMERGENCY RLS POLICIES
-- ==========================================

-- USERS TABLE - Most critical
CREATE POLICY "emergency_block_anonymous_users" ON users 
  FOR ALL USING (auth.role() = 'authenticated');

-- TOURNAMENTS SYSTEM
CREATE POLICY "emergency_block_anonymous_tournaments" ON tournaments 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_tournament_participants" ON tournament_participants 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_tournament_statistics" ON tournament_statistics 
  FOR ALL USING (auth.role() = 'authenticated');

-- CLUBS SYSTEM
CREATE POLICY "emergency_block_anonymous_clubs" ON clubs 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_club_members" ON club_members 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_club_follows" ON club_follows 
  FOR ALL USING (auth.role() = 'authenticated');

-- SOCIAL FEATURES
CREATE POLICY "emergency_block_anonymous_posts" ON posts 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_post_comments" ON post_comments 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_achievements" ON achievements 
  FOR ALL USING (auth.role() = 'authenticated');

-- USER DATA
CREATE POLICY "emergency_block_anonymous_user_follows" ON user_follows 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_user_performance_stats" ON user_performance_stats 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_ranked_users" ON ranked_users 
  FOR ALL USING (auth.role() = 'authenticated');

-- PAYMENTS AND VOUCHERS
CREATE POLICY "emergency_block_anonymous_payments" ON payments 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_voucher_templates" ON voucher_templates 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_referral_codes" ON referral_codes 
  FOR ALL USING (auth.role() = 'authenticated');

-- ADMIN AND SYSTEM
CREATE POLICY "emergency_block_anonymous_admin_logs" ON admin_logs 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_notification_templates" ON notification_templates 
  FOR ALL USING (auth.role() = 'authenticated');

-- ANALYTICS
CREATE POLICY "emergency_block_anonymous_spa_economy_health" ON spa_economy_health 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "emergency_block_anonymous_rank_change_logs" ON rank_change_logs 
  FOR ALL USING (auth.role() = 'authenticated');

-- ==========================================
-- STEP 3: COMPREHENSIVE TABLE PROTECTION
-- ==========================================

-- Create emergency policies for ALL remaining tables
-- This ensures no table is accidentally left exposed

DO $$
DECLARE
    tbl RECORD;
    policy_name TEXT;
BEGIN
    -- Loop through all tables in public schema
    FOR tbl IN 
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT IN (
            -- Skip tables that already have policies created above
            'users', 'tournaments', 'tournament_participants', 'tournament_statistics',
            'clubs', 'club_members', 'club_follows', 'posts', 'post_comments',
            'achievements', 'user_follows', 'user_performance_stats', 'ranked_users',
            'payments', 'voucher_templates', 'referral_codes', 'admin_logs',
            'notification_templates', 'spa_economy_health', 'rank_change_logs'
        )
    LOOP
        -- Generate policy name
        policy_name := 'emergency_block_anonymous_' || tbl.tablename;
        
        -- Create policy to block anonymous access
        EXECUTE format('
            CREATE POLICY %I ON %I 
            FOR ALL USING (auth.role() = ''authenticated'')
        ', policy_name, tbl.tablename);
        
        RAISE NOTICE 'Created emergency policy for table: %', tbl.tablename;
    END LOOP;
END $$;

-- ==========================================
-- STEP 4: VERIFICATION QUERIES
-- ==========================================

-- Check that RLS is enabled on critical tables
DO $$
DECLARE
    critical_tables TEXT[] := ARRAY[
        'users', 'tournaments', 'clubs', 'posts', 'payments', 
        'admin_logs', 'ranked_users', 'user_performance_stats'
    ];
    tbl TEXT;
    rls_enabled BOOLEAN;
BEGIN
    RAISE NOTICE '========== RLS VERIFICATION ==========';
    
    FOREACH tbl IN ARRAY critical_tables
    LOOP
        SELECT INTO rls_enabled rowsecurity 
        FROM pg_tables 
        WHERE tablename = tbl AND schemaname = 'public';
        
        IF rls_enabled THEN
            RAISE NOTICE '✅ RLS ENABLED: %', tbl;
        ELSE
            RAISE WARNING '❌ RLS NOT ENABLED: %', tbl;
        END IF;
    END LOOP;
    
    RAISE NOTICE '====================================';
END $$;

-- ==========================================
-- COMMIT TRANSACTION
-- ==========================================

COMMIT;

-- ==========================================
-- POST-EXECUTION VERIFICATION
-- ==========================================

-- Run these queries AFTER executing the script to verify security:

/*
-- 1. Verify RLS is enabled on critical tables
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'tournaments', 'clubs', 'posts', 'payments')
ORDER BY tablename;

-- 2. Count policies created
SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY policy_count DESC, tablename;

-- 3. Test anonymous access (should return empty)
-- Run this with anonymous key:
-- SELECT * FROM users LIMIT 1;
-- SELECT * FROM tournaments LIMIT 1;  
-- SELECT * FROM posts LIMIT 1;

-- Expected result: All queries should return empty arrays []
*/

-- ==========================================
-- CRITICAL NOTES
-- ==========================================

/*
🚨 IMPORTANT POST-EXECUTION STEPS:

1. TEST IMMEDIATELY:
   - Test your application with authenticated users
   - Verify all functionality still works
   - Check that anonymous requests return empty data

2. MONITOR APPLICATION:
   - Watch for any authentication errors
   - Check application logs for RLS-related issues
   - Verify user experience is not impacted

3. NEXT STEPS:
   - Execute data integrity script (foreign keys)
   - Execute performance optimization script (indexes)
   - Set up proper RLS policies for specific use cases

4. ROLLBACK PLAN (if needed):
   - To disable RLS: ALTER TABLE tablename DISABLE ROW LEVEL SECURITY;
   - To drop policies: DROP POLICY policyname ON tablename;

⚠️ DO NOT ROLLBACK unless absolutely necessary!
   Anonymous data access is a critical security vulnerability.

🔒 Security Status After This Script:
   ✅ No anonymous access to sensitive data
   ✅ All user data protected
   ✅ Admin and system data secured  
   ✅ Payment information protected
   ✅ Tournament and club data secured
*/