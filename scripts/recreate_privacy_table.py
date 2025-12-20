#!/usr/bin/env python3
"""
Re-apply privacy settings table migration to ensure all columns exist
"""
import psycopg2
import json
from pathlib import Path

# Load credentials
env_path = Path(__file__).parent.parent / 'env.json'
with open(env_path) as f:
    env = json.load(f)

# Load migration SQL
migration_sql = """
-- Drop and recreate table to ensure correct schema
DROP TABLE IF EXISTS user_privacy_settings CASCADE;

CREATE TABLE user_privacy_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- Profile visibility
    profile_public BOOLEAN DEFAULT TRUE,
    show_email BOOLEAN DEFAULT FALSE,
    show_phone BOOLEAN DEFAULT FALSE,
    show_location BOOLEAN DEFAULT TRUE,
    show_stats BOOLEAN DEFAULT TRUE,
    
    -- Activity visibility
    show_online_status BOOLEAN DEFAULT TRUE,
    show_match_history BOOLEAN DEFAULT TRUE,
    show_tournaments BOOLEAN DEFAULT TRUE,
    
    -- Search & discoverability
    searchable BOOLEAN DEFAULT TRUE,
    allow_friend_requests BOOLEAN DEFAULT TRUE,
    allow_messages BOOLEAN DEFAULT TRUE,
    
    -- Notifications preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for privacy lookups
CREATE INDEX IF NOT EXISTS idx_privacy_settings_user_id ON user_privacy_settings(user_id);

-- RLS for privacy settings
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own privacy settings" ON user_privacy_settings;
CREATE POLICY "Users can view their own privacy settings"
    ON user_privacy_settings FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own privacy settings" ON user_privacy_settings;
CREATE POLICY "Users can update their own privacy settings"
    ON user_privacy_settings FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own privacy settings" ON user_privacy_settings;
CREATE POLICY "Users can insert their own privacy settings"
    ON user_privacy_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Trigger to create default privacy settings for new users
CREATE OR REPLACE FUNCTION create_default_privacy_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_privacy_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_create_default_privacy_settings ON users;
CREATE TRIGGER trigger_create_default_privacy_settings
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_privacy_settings();

-- Insert defaults for ALL existing users
INSERT INTO user_privacy_settings (user_id)
SELECT id FROM users
ON CONFLICT (user_id) DO NOTHING;
"""

# Connect to database (using transaction pooler port 6543)
conn = psycopg2.connect(
    host=env['SUPABASE_DB_HOST'],
    port=6543,
    database='postgres',
    user=env['SUPABASE_DB_USER'],
    password=env['SUPABASE_DB_PASSWORD']
)

cur = conn.cursor()

print("=" * 80)
print("RECREATING user_privacy_settings TABLE")
print("=" * 80)

try:
    # Execute migration
    cur.execute(migration_sql)
    conn.commit()
    print("\n✅ Migration applied successfully!")
    
    # Verify
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'user_privacy_settings'
        ORDER BY ordinal_position;
    """)
    
    columns = cur.fetchall()
    print(f"\nColumns in table ({len(columns)}):")
    for col_name, data_type in columns:
        print(f"  ✓ {col_name:30} {data_type}")
    
    # Check row count
    cur.execute("SELECT COUNT(*) FROM user_privacy_settings;")
    count = cur.fetchone()[0]
    
    cur.execute("SELECT COUNT(*) FROM users;")
    user_count = cur.fetchone()[0]
    
    print(f"\nData:")
    print(f"  Users: {user_count}")
    print(f"  Privacy settings: {count}")
    
    if count == user_count:
        print(f"\n✅ All {user_count} users now have privacy settings!")
    else:
        print(f"\n⚠️  Missing privacy settings for {user_count - count} users")
    
except Exception as e:
    conn.rollback()
    print(f"\n❌ Error: {e}")
finally:
    cur.close()
    conn.close()

print("\n" + "=" * 80)
print("Done! Now hot reload the app (press 'r' in Flutter terminal)")
print("=" * 80)
