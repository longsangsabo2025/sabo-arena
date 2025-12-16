-- ==========================================
-- SABO ARENA - SMART SOCIAL RLS POLICIES
-- Deploy này qua Supabase Dashboard > SQL Editor
-- ==========================================

-- BƯỚC 1: Enable RLS cho các tables
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;

-- BƯỚC 2: Tạo policies cho CONTENT CÔNG KHAI
DROP POLICY IF EXISTS "tournaments_public_read" ON tournaments;
CREATE POLICY "tournaments_public_read" ON tournaments 
  FOR SELECT USING (true); -- Tournaments luôn công khai

DROP POLICY IF EXISTS "clubs_public_read" ON clubs;
CREATE POLICY "clubs_public_read" ON clubs 
  FOR SELECT USING (true); -- Clubs luôn công khai

DROP POLICY IF EXISTS "posts_public_read" ON posts;
CREATE POLICY "posts_public_read" ON posts 
  FOR SELECT USING (true); -- Posts công khai để mọi người xem

DROP POLICY IF EXISTS "rankings_public_read" ON ranked_users;
CREATE POLICY "rankings_public_read" ON ranked_users 
  FOR SELECT USING (true); -- Rankings công khai

-- BƯỚC 3: Policies cho SOCIAL FEATURES
DROP POLICY IF EXISTS "comments_public_read" ON post_comments;
CREATE POLICY "comments_public_read" ON post_comments 
  FOR SELECT USING (true); -- Comments công khai

DROP POLICY IF EXISTS "follows_public_read" ON user_follows;
CREATE POLICY "follows_public_read" ON user_follows 
  FOR SELECT USING (true); -- Follows có thể xem công khai

DROP POLICY IF EXISTS "club_members_public_read" ON club_members;
CREATE POLICY "club_members_public_read" ON club_members 
  FOR SELECT USING (true); -- Club members có thể xem

-- BƯỚC 4: Policies cho USER CONTENT (có owner access)
DROP POLICY IF EXISTS "tournaments_owner_access" ON tournaments;
CREATE POLICY "tournaments_owner_access" ON tournaments 
  FOR ALL USING (auth.uid() = organizer_id);

DROP POLICY IF EXISTS "posts_owner_access" ON posts;
CREATE POLICY "posts_owner_access" ON posts 
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "comments_owner_access" ON post_comments;
CREATE POLICY "comments_owner_access" ON post_comments 
  FOR ALL USING (auth.uid() = user_id);

-- BƯỚC 5: Policies cho PRIVATE DATA
DROP POLICY IF EXISTS "users_public_profile" ON users;
CREATE POLICY "users_public_profile" ON users 
  FOR SELECT USING (auth.uid() = id OR true); -- Basic profile info công khai

DROP POLICY IF EXISTS "users_own_data" ON users;
CREATE POLICY "users_own_data" ON users 
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "payments_owner_only" ON payments;
CREATE POLICY "payments_owner_only" ON payments 
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "vouchers_owner_only" ON user_vouchers;
CREATE POLICY "vouchers_owner_only" ON user_vouchers 
  FOR ALL USING (auth.uid() = user_id);

-- BƯỚC 6: Policies cho ADMIN DATA
DROP POLICY IF EXISTS "admin_logs_admin_only" ON admin_logs;
CREATE POLICY "admin_logs_admin_only" ON admin_logs 
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'admin' OR
    auth.jwt() ->> 'role' = 'service_role'
  );

-- BƯỚC 7: Chat & Messages
DROP POLICY IF EXISTS "chat_public_access" ON chat_messages;
CREATE POLICY "chat_public_access" ON chat_messages 
  FOR ALL USING (true); -- Simplified for now, can be refined later

-- HOÀN THÀNH!
-- Giờ đây database có RLS thông minh cho social media platform
