-- ==========================================
-- SABO ARENA - PRODUCTION READINESS FIXES
-- Generated: 2025-10-23T14:38:04.093420
-- Tables found: 119
-- ==========================================

BEGIN;

-- 1. ENABLE ROW LEVEL SECURITY (Critical for all data tables)
ALTER TABLE hidden_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranking_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_economy_health ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_formats ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_spa_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_detection_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_breaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE geometry_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_performance_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_payment_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE voucher_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_spa_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotion_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE rank_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE rank_change_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE popular_hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_quick_help ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_journey_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_elo_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_eligibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE prize_pool_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_completion_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_payment_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE voucher_registration_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE geography_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_challenges_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_guide_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE rank_system ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_guides ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_analytics_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservation_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE recent_tournament_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE spa_reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE voucher_usage_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE elo_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE handicap_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_formats ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_configurations ENABLE ROW LEVEL SECURITY;

-- 2. CREATE BASIC RLS POLICIES (Customize based on your needs)

-- Basic policies for hidden_posts
CREATE POLICY "authenticated_read_hidden_posts" ON hidden_posts 
  FOR SELECT USING (auth.role() = 'authenticated');
  
CREATE POLICY "authenticated_insert_hidden_posts" ON hidden_posts 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Basic policies for ranking_definitions
CREATE POLICY "authenticated_read_ranking_definitions" ON ranking_definitions 
  FOR SELECT USING (auth.role() = 'authenticated');
  
CREATE POLICY "authenticated_insert_ranking_definitions" ON ranking_definitions 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Basic policies for post_comments
CREATE POLICY "authenticated_read_post_comments" ON post_comments 
  FOR SELECT USING (auth.role() = 'authenticated');
  
CREATE POLICY "authenticated_insert_post_comments" ON post_comments 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Basic policies for saved_posts
CREATE POLICY "authenticated_read_saved_posts" ON saved_posts 
  FOR SELECT USING (auth.role() = 'authenticated');
  
CREATE POLICY "authenticated_insert_saved_posts" ON saved_posts 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Basic policies for scheduled_notifications
CREATE POLICY "authenticated_read_scheduled_notifications" ON scheduled_notifications 
  FOR SELECT USING (auth.role() = 'authenticated');
  
CREATE POLICY "authenticated_insert_scheduled_notifications" ON scheduled_notifications 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 3. ADD ESSENTIAL INDEXES (Add more based on your query patterns)
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON tournaments(status);

COMMIT;
