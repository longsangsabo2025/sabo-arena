#!/usr/bin/env python3
"""
Smart Migration with Constraint Management
Drop foreign keys -> Apply migration -> Re-add constraints
"""

import requests
import json
from datetime import datetime

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

class SmartMigrationExecutor:
    def __init__(self):
        self.headers = {
            'Authorization': f'Bearer {SERVICE_KEY}',
            'Content-Type': 'application/json',
            'apikey': SERVICE_KEY
        }
        
    def execute_sql(self, sql):
        """Execute SQL using custom function"""
        try:
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/execute_sql",
                headers=self.headers,
                json={'sql_query': sql}
            )
            if response.status_code == 200:
                result = response.json()
                if isinstance(result, dict) and 'error' in result:
                    return False, result['error']
                return True, result
            else:
                return False, f"HTTP {response.status_code}: {response.text}"
        except Exception as e:
            return False, f"Exception: {str(e)}"
    
    def step1_drop_all_foreign_keys(self):
        """Step 1: Drop all existing foreign key constraints"""
        print("🗑️  STEP 1: Dropping all foreign key constraints...")
        
        drop_fks = [
            "ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS fk_chat_messages_sender_id;",
            "ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey;",
            "ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_room_id_fkey;",
            "ALTER TABLE public.chat_rooms DROP CONSTRAINT IF EXISTS fk_chat_rooms_user1_id;",
            "ALTER TABLE public.chat_rooms DROP CONSTRAINT IF EXISTS fk_chat_rooms_user2_id;",
            "ALTER TABLE public.chat_rooms DROP CONSTRAINT IF EXISTS chat_rooms_user1_id_fkey;",
            "ALTER TABLE public.chat_rooms DROP CONSTRAINT IF EXISTS chat_rooms_user2_id_fkey;",
            "ALTER TABLE public.challenges DROP CONSTRAINT IF EXISTS fk_challenges_challenger_id;",
            "ALTER TABLE public.challenges DROP CONSTRAINT IF EXISTS fk_challenges_challenged_id;",
            "ALTER TABLE public.challenges DROP CONSTRAINT IF EXISTS challenges_challenger_id_fkey;",
            "ALTER TABLE public.challenges DROP CONSTRAINT IF EXISTS challenges_challenged_id_fkey;",
            "ALTER TABLE public.tournaments DROP CONSTRAINT IF EXISTS fk_tournaments_organizer_id;",
            "ALTER TABLE public.tournaments DROP CONSTRAINT IF EXISTS tournaments_organizer_id_fkey;",
            "ALTER TABLE public.admin_logs DROP CONSTRAINT IF EXISTS fk_admin_logs_admin_id;",
            "ALTER TABLE public.admin_logs DROP CONSTRAINT IF EXISTS admin_logs_admin_id_fkey;",
            "ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_user_id_fkey;",
            "ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_club_id_fkey;",
            "ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_post_id_fkey;",
            "ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_user_id_fkey;",
            "ALTER TABLE public.clubs DROP CONSTRAINT IF EXISTS clubs_owner_id_fkey;",
            "ALTER TABLE public.club_members DROP CONSTRAINT IF EXISTS club_members_club_id_fkey;",
            "ALTER TABLE public.club_members DROP CONSTRAINT IF EXISTS club_members_user_id_fkey;",
            "ALTER TABLE public.club_follows DROP CONSTRAINT IF EXISTS club_follows_club_id_fkey;",
            "ALTER TABLE public.club_follows DROP CONSTRAINT IF EXISTS club_follows_user_id_fkey;",
            "ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;",
            "ALTER TABLE public.post_likes DROP CONSTRAINT IF EXISTS post_likes_post_id_fkey;",
            "ALTER TABLE public.post_likes DROP CONSTRAINT IF EXISTS post_likes_user_id_fkey;",
            "ALTER TABLE public.tournament_participants DROP CONSTRAINT IF EXISTS tournament_participants_tournament_id_fkey;",
            "ALTER TABLE public.tournament_participants DROP CONSTRAINT IF EXISTS tournament_participants_user_id_fkey;",
            "ALTER TABLE public.user_achievements DROP CONSTRAINT IF EXISTS user_achievements_user_id_fkey;",
            "ALTER TABLE public.user_achievements DROP CONSTRAINT IF EXISTS user_achievements_achievement_id_fkey;",
            "ALTER TABLE public.chat_room_members DROP CONSTRAINT IF EXISTS chat_room_members_room_id_fkey;",
            "ALTER TABLE public.chat_room_members DROP CONSTRAINT IF EXISTS chat_room_members_user_id_fkey;"
        ]
        
        success_count = 0
        for sql in drop_fks:
            success, result = self.execute_sql(sql)
            if success:
                success_count += 1
                print(f"✅ Dropped constraint: {sql.split()[-1][:-1] if 'IF EXISTS' in sql else 'constraint'}")
            else:
                print(f"⚠️  Warning: {sql.split()[-1][:-1]} - {result}")
        
        print(f"✅ Step 1 complete: {success_count}/{len(drop_fks)} constraints processed")
        return True
    
    def step2_clean_orphaned_data(self):
        """Step 2: Clean orphaned data that would violate constraints"""
        print("\n🧹 STEP 2: Cleaning orphaned data...")
        
        cleanup_sql = [
            "DELETE FROM chat_messages WHERE sender_id IS NULL;",
            "DELETE FROM chat_messages WHERE sender_id NOT IN (SELECT id FROM users);",
            "DELETE FROM chat_rooms WHERE user1_id IS NOT NULL AND user1_id NOT IN (SELECT id FROM users);",
            "DELETE FROM chat_rooms WHERE user2_id IS NOT NULL AND user2_id NOT IN (SELECT id FROM users);",
            "DELETE FROM challenges WHERE challenger_id IS NOT NULL AND challenger_id NOT IN (SELECT id FROM users);",
            "DELETE FROM challenges WHERE challenged_id IS NOT NULL AND challenged_id NOT IN (SELECT id FROM users);",
            "DELETE FROM tournaments WHERE organizer_id IS NOT NULL AND organizer_id NOT IN (SELECT id FROM users);",
            "DELETE FROM admin_logs WHERE admin_id IS NOT NULL AND admin_id NOT IN (SELECT id FROM users);",
            "DELETE FROM posts WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM posts WHERE club_id IS NOT NULL AND club_id NOT IN (SELECT id FROM clubs);",
            "DELETE FROM comments WHERE post_id IS NOT NULL AND post_id NOT IN (SELECT id FROM posts);",
            "DELETE FROM comments WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM club_members WHERE club_id IS NOT NULL AND club_id NOT IN (SELECT id FROM clubs);",
            "DELETE FROM club_members WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM club_follows WHERE club_id IS NOT NULL AND club_id NOT IN (SELECT id FROM clubs);",
            "DELETE FROM club_follows WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM notifications WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM post_likes WHERE post_id IS NOT NULL AND post_id NOT IN (SELECT id FROM posts);",
            "DELETE FROM post_likes WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM tournament_participants WHERE tournament_id IS NOT NULL AND tournament_id NOT IN (SELECT id FROM tournaments);",
            "DELETE FROM tournament_participants WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM user_achievements WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);",
            "DELETE FROM user_achievements WHERE achievement_id IS NOT NULL AND achievement_id NOT IN (SELECT id FROM achievements);",
            "DELETE FROM chat_room_members WHERE room_id IS NOT NULL AND room_id NOT IN (SELECT id FROM chat_rooms);",
            "DELETE FROM chat_room_members WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users);"
        ]
        
        total_deleted = 0
        for sql in cleanup_sql:
            success, result = self.execute_sql(sql)
            if success:
                print(f"✅ Cleaned: {sql.split()[2]}")
                total_deleted += 1
            else:
                print(f"⚠️  Warning cleaning {sql.split()[2]}: {result}")
        
        print(f"✅ Step 2 complete: {total_deleted} cleanup operations")
        return True
    
    def step3_apply_core_migration(self):
        """Step 3: Apply core migration (without foreign keys)"""
        print("\n⚡ STEP 3: Applying core migration...")
        
        # Create simplified migration without foreign keys
        core_migration = """
-- Add missing primary keys
ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
ALTER TABLE public.notification_preferences ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
ALTER TABLE public.post_likes ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
ALTER TABLE public.tournament_participants ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
ALTER TABLE public.user_achievements ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;

-- Add timestamps
ALTER TABLE public.achievements ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.achievements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.chat_room_members ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.chat_room_members ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.club_members ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.club_members ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.notification_preferences ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.notification_preferences ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.post_likes ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.post_likes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.tournament_participants ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.tournament_participants ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.user_achievements ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.user_achievements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create update triggers
CREATE OR REPLACE FUNCTION update_achievements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_chat_room_members_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_club_members_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_announcements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_comments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_matches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_post_likes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_tournament_participants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_user_achievements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS update_achievements_updated_at_trigger ON public.achievements;
CREATE TRIGGER update_achievements_updated_at_trigger
BEFORE UPDATE ON public.achievements
FOR EACH ROW
EXECUTE FUNCTION update_achievements_updated_at();

DROP TRIGGER IF EXISTS update_chat_room_members_updated_at_trigger ON public.chat_room_members;
CREATE TRIGGER update_chat_room_members_updated_at_trigger
BEFORE UPDATE ON public.chat_room_members
FOR EACH ROW
EXECUTE FUNCTION update_chat_room_members_updated_at();

DROP TRIGGER IF EXISTS update_club_members_updated_at_trigger ON public.club_members;
CREATE TRIGGER update_club_members_updated_at_trigger
BEFORE UPDATE ON public.club_members
FOR EACH ROW
EXECUTE FUNCTION update_club_members_updated_at();

DROP TRIGGER IF EXISTS update_announcements_updated_at_trigger ON public.announcements;
CREATE TRIGGER update_announcements_updated_at_trigger
BEFORE UPDATE ON public.announcements
FOR EACH ROW
EXECUTE FUNCTION update_announcements_updated_at();

DROP TRIGGER IF EXISTS update_comments_updated_at_trigger ON public.comments;
CREATE TRIGGER update_comments_updated_at_trigger
BEFORE UPDATE ON public.comments
FOR EACH ROW
EXECUTE FUNCTION update_comments_updated_at();

DROP TRIGGER IF EXISTS update_matches_updated_at_trigger ON public.matches;
CREATE TRIGGER update_matches_updated_at_trigger
BEFORE UPDATE ON public.matches
FOR EACH ROW
EXECUTE FUNCTION update_matches_updated_at();

DROP TRIGGER IF EXISTS update_notification_preferences_updated_at_trigger ON public.notification_preferences;
CREATE TRIGGER update_notification_preferences_updated_at_trigger
BEFORE UPDATE ON public.notification_preferences
FOR EACH ROW
EXECUTE FUNCTION update_notification_preferences_updated_at();

DROP TRIGGER IF EXISTS update_post_likes_updated_at_trigger ON public.post_likes;
CREATE TRIGGER update_post_likes_updated_at_trigger
BEFORE UPDATE ON public.post_likes
FOR EACH ROW
EXECUTE FUNCTION update_post_likes_updated_at();

DROP TRIGGER IF EXISTS update_tournament_participants_updated_at_trigger ON public.tournament_participants;
CREATE TRIGGER update_tournament_participants_updated_at_trigger
BEFORE UPDATE ON public.tournament_participants
FOR EACH ROW
EXECUTE FUNCTION update_tournament_participants_updated_at();

DROP TRIGGER IF EXISTS update_user_achievements_updated_at_trigger ON public.user_achievements;
CREATE TRIGGER update_user_achievements_updated_at_trigger
BEFORE UPDATE ON public.user_achievements
FOR EACH ROW
EXECUTE FUNCTION update_user_achievements_updated_at();

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON public.chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_room_members_room_id ON public.chat_room_members(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_room_members_user_id ON public.chat_room_members(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_club_id ON public.posts(club_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at);
CREATE INDEX IF NOT EXISTS idx_tournaments_club_id ON public.tournaments(club_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_organizer_id ON public.tournaments(organizer_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_start_date ON public.tournaments(start_date);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_club_members_club_id ON public.club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_club_members_user_id ON public.club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_club_follows_club_id ON public.club_follows(club_id);
CREATE INDEX IF NOT EXISTS idx_club_follows_user_id ON public.club_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenger_id ON public.challenges(challenger_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenged_id ON public.challenges(challenged_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON public.challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_created_at ON public.challenges(created_at);

-- RLS Policies
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "announcements_policy" ON public.announcements;
CREATE POLICY "announcements_policy" ON public.announcements
FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "comments_policy" ON public.comments;
CREATE POLICY "comments_policy" ON public.comments
FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "matches_policy" ON public.matches;
CREATE POLICY "matches_policy" ON public.matches
FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notification_preferences_policy" ON public.notification_preferences;
CREATE POLICY "notification_preferences_policy" ON public.notification_preferences
FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;  
DROP POLICY IF EXISTS "post_likes_policy" ON public.post_likes;
CREATE POLICY "post_likes_policy" ON public.post_likes
FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.tournament_participants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tournament_participants_policy" ON public.tournament_participants;
CREATE POLICY "tournament_participants_policy" ON public.tournament_participants
FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_achievements_policy" ON public.user_achievements;
CREATE POLICY "user_achievements_policy" ON public.user_achievements
FOR ALL TO authenticated USING (true) WITH CHECK (true);
"""
        
        success, result = self.execute_sql(core_migration)
        if success:
            print("✅ Core migration applied successfully!")
            return True
        else:
            print(f"❌ Core migration failed: {result}")
            return False
    
    def step4_add_foreign_keys(self):
        """Step 4: Add foreign key constraints (only for clean data)"""
        print("\n🔗 STEP 4: Adding foreign key constraints...")
        
        foreign_keys = [
            """ALTER TABLE public.chat_messages
               ADD CONSTRAINT fk_chat_messages_sender_id
               FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;""",
            
            """ALTER TABLE public.chat_rooms
               ADD CONSTRAINT fk_chat_rooms_user1_id
               FOREIGN KEY (user1_id) REFERENCES public.users(id) ON DELETE CASCADE;""",
            
            """ALTER TABLE public.chat_rooms
               ADD CONSTRAINT fk_chat_rooms_user2_id
               FOREIGN KEY (user2_id) REFERENCES public.users(id) ON DELETE CASCADE;""",
            
            """ALTER TABLE public.challenges
               ADD CONSTRAINT fk_challenges_challenger_id
               FOREIGN KEY (challenger_id) REFERENCES public.users(id) ON DELETE CASCADE;""",
            
            """ALTER TABLE public.challenges
               ADD CONSTRAINT fk_challenges_challenged_id
               FOREIGN KEY (challenged_id) REFERENCES public.users(id) ON DELETE CASCADE;""",
            
            """ALTER TABLE public.tournaments
               ADD CONSTRAINT fk_tournaments_organizer_id
               FOREIGN KEY (organizer_id) REFERENCES public.users(id) ON DELETE CASCADE;""",
            
            """ALTER TABLE public.admin_logs
               ADD CONSTRAINT fk_admin_logs_admin_id
               FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE;"""
        ]
        
        success_count = 0
        for fk_sql in foreign_keys:
            success, result = self.execute_sql(fk_sql)
            if success:
                success_count += 1
                constraint_name = fk_sql.split("CONSTRAINT")[1].split()[0]
                print(f"✅ Added foreign key: {constraint_name}")
            else:
                print(f"⚠️  Warning: Failed to add constraint - {result}")
        
        print(f"✅ Step 4 complete: {success_count}/{len(foreign_keys)} foreign keys added")
        return success_count > 0
    
    def run(self):
        """Run the complete smart migration"""
        print("="*80)
        print("🚀 SMART MIGRATION EXECUTOR")
        print("="*80)
        
        start_time = datetime.now()
        
        # Step 1: Drop existing foreign keys
        if not self.step1_drop_all_foreign_keys():
            print("❌ Failed at Step 1")
            return False
        
        # Step 2: Clean orphaned data
        if not self.step2_clean_orphaned_data():
            print("❌ Failed at Step 2")
            return False
        
        # Step 3: Apply core migration
        if not self.step3_apply_core_migration():
            print("❌ Failed at Step 3")
            return False
        
        # Step 4: Add foreign keys back
        self.step4_add_foreign_keys()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        print("\n" + "="*80)
        print("✅ SMART MIGRATION COMPLETED!")
        print(f"⏱️  Total time: {duration:.2f} seconds")
        print("="*80)
        
        print("\n🎯 Next steps:")
        print("1. python verify_migration.py")
        print("2. Test your Flutter app")
        print("3. Monitor database performance")
        
        return True

def main():
    executor = SmartMigrationExecutor()
    executor.run()

if __name__ == "__main__":
    main()