-- ==========================================
-- SABO ARENA - SMART RLS POLICIES FOR SOCIAL PLATFORM
-- Phù hợp cho nền tảng mạng xã hội
-- ==========================================

BEGIN;

-- ==========================================
-- 1. PUBLIC CONTENT (Nội dung công khai)
-- ==========================================

-- TOURNAMENTS - Công khai để mọi người xem
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tournaments_public_read" ON tournaments 
  FOR SELECT USING (is_public = true);
CREATE POLICY "tournaments_owner_full_access" ON tournaments 
  FOR ALL USING (auth.uid() = organizer_id);
CREATE POLICY "tournaments_authenticated_create" ON tournaments 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- CLUBS - Thông tin CLB công khai
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clubs_public_read" ON clubs 
  FOR SELECT USING (is_active = true);
CREATE POLICY "clubs_members_write" ON clubs 
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM club_members 
      WHERE club_id = clubs.id AND role IN ('owner', 'admin')
    )
  );

-- POSTS - Mạng xã hội cần posts công khai
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "posts_public_read" ON posts 
  FOR SELECT USING (is_public = true);
CREATE POLICY "posts_followers_read" ON posts 
  FOR SELECT USING (
    is_public = false AND 
    (auth.uid() = user_id OR 
     auth.uid() IN (
       SELECT follower_id FROM user_follows 
       WHERE following_id = posts.user_id
     ))
  );
CREATE POLICY "posts_owner_full_access" ON posts 
  FOR ALL USING (auth.uid() = user_id);

-- RANKINGS - Bảng xếp hạng nên công khai
ALTER TABLE ranked_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rankings_public_read" ON ranked_users 
  FOR SELECT USING (true); -- Công khai hoàn toàn

-- ==========================================
-- 2. SOCIAL FEATURES (Tính năng xã hội)
-- ==========================================

-- POST COMMENTS - Công khai với bài post công khai
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "comments_public_posts_read" ON post_comments 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM posts 
      WHERE posts.id = post_comments.post_id 
      AND posts.is_public = true
    )
  );
CREATE POLICY "comments_owner_full_access" ON post_comments 
  FOR ALL USING (auth.uid() = user_id);

-- USER FOLLOWS - Tùy cài đặt riêng tư
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "follows_public_profiles_read" ON user_follows 
  FOR SELECT USING (
    auth.uid() = follower_id OR 
    auth.uid() = following_id OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = user_follows.following_id 
      AND users.profile_public = true
    )
  );

-- CLUB MEMBERS - Tùy setting của CLB
ALTER TABLE club_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "club_members_public_clubs_read" ON club_members 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM clubs 
      WHERE clubs.id = club_members.club_id 
      AND clubs.members_visible = true
    ) OR
    auth.uid() = user_id OR
    auth.uid() IN (
      SELECT user_id FROM club_members cm2 
      WHERE cm2.club_id = club_members.club_id
    )
  );

-- ==========================================
-- 3. PRIVATE CONTENT (Nội dung riêng tư)
-- ==========================================

-- USERS - Thông tin cá nhân chi tiết
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_public_profile_read" ON users 
  FOR SELECT USING (
    -- Chỉ hiển thị thông tin công khai
    auth.uid() = id OR
    profile_public = true
  );
CREATE POLICY "users_own_profile_write" ON users 
  FOR UPDATE USING (auth.uid() = id);

-- PAYMENTS - Hoàn toàn riêng tư
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payments_owner_only" ON payments 
  FOR ALL USING (auth.uid() = user_id);

-- CHAT MESSAGES - Riêng tư giữa các thành viên
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_messages_room_members" ON chat_messages 
  FOR ALL USING (
    auth.uid() IN (
      SELECT user_id FROM chat_room_members 
      WHERE room_id = chat_messages.room_id
    )
  );

-- USER VOUCHERS - Cá nhân
ALTER TABLE user_vouchers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "vouchers_owner_only" ON user_vouchers 
  FOR ALL USING (auth.uid() = user_id);

-- ADMIN LOGS - Chỉ admin
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_logs_admin_only" ON admin_logs 
  FOR ALL USING (
    auth.jwt() ->> 'role' = 'admin' OR
    auth.jwt() ->> 'role' = 'service_role'
  );

-- ==========================================
-- 4. CONTEXTUAL ACCESS (Truy cập theo ngữ cảnh)
-- ==========================================

-- TOURNAMENT PARTICIPANTS - Công khai cho giải công khai
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "participants_public_tournaments" ON tournament_participants 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tournaments 
      WHERE tournaments.id = tournament_participants.tournament_id 
      AND tournaments.is_public = true
    ) OR
    auth.uid() = user_id
  );

COMMIT;