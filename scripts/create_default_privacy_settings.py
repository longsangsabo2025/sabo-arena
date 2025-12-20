"""
Create default privacy settings for all existing users
"""
import psycopg2
import json
from datetime import datetime

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False
cur = conn.cursor()

print('🔧 Creating Default Privacy Settings for All Users')
print('=' * 70)

try:
    # Get all users without privacy settings
    print('\n📊 Finding users without privacy settings...')
    cur.execute("""
        SELECT u.id, u.full_name, u.email
        FROM users u
        LEFT JOIN user_privacy_settings ups ON u.id = ups.user_id
        WHERE ups.user_id IS NULL
    """)
    
    users_without_settings = cur.fetchall()
    count = len(users_without_settings)
    
    if count == 0:
        print('  ✅ All users already have privacy settings')
    else:
        print(f'  Found {count} users without privacy settings')
        
        # Create default settings for each user
        print('\n📝 Creating default settings...')
        now = datetime.now().isoformat()
        
        for user_id, full_name, email in users_without_settings:
            cur.execute("""
                INSERT INTO user_privacy_settings (
                    user_id, 
                    profile_public, show_email, show_phone, show_location, show_stats,
                    show_online_status, show_match_history, show_tournaments,
                    searchable, allow_friend_requests, allow_messages,
                    email_notifications, push_notifications,
                    created_at, updated_at
                ) VALUES (
                    %s,
                    TRUE, FALSE, FALSE, TRUE, TRUE,
                    TRUE, TRUE, TRUE,
                    TRUE, TRUE, TRUE,
                    TRUE, TRUE,
                    %s, %s
                )
            """, (user_id, now, now))
            
            print(f'  ✓ {email or full_name}')
        
        conn.commit()
        print(f'\n✅ Created default privacy settings for {count} users')
    
    # Verify
    print('\n📊 Final count:')
    cur.execute("SELECT COUNT(*) FROM user_privacy_settings")
    total = cur.fetchone()[0]
    print(f'  Total privacy settings: {total}')
    
    cur.execute("SELECT COUNT(*) FROM users")
    total_users = cur.fetchone()[0]
    print(f'  Total users: {total_users}')
    
    if total == total_users:
        print('  ✅ All users have privacy settings!')
    else:
        print(f'  ⚠️  Missing {total_users - total} settings')

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR: {e}')
    import traceback
    traceback.print_exc()
finally:
    conn.close()

print('\n' + '=' * 70)
