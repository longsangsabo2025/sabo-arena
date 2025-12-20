"""
DELETE all demo/test users using transaction pooler for speed
"""
import psycopg2
import json

# Load env
with open('env.json', 'r') as f:
    env = json.load(f)

# Use transaction pooler for SPEED
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False

cur = conn.cursor()

print('💥 DELETING ALL DEMO/TEST USERS\n')
print('=' * 60)

try:
    # Get all demo/test user IDs
    cur.execute("""
        SELECT id, username, full_name, created_at 
        FROM users 
        WHERE username ILIKE 'test%' 
           OR username ILIKE 'demo%' 
           OR username ILIKE 'sabo%'
        ORDER BY created_at
    """)
    
    users = cur.fetchall()
    user_ids = [u[0] for u in users]
    
    if not users:
        print('✅ No demo users found. Database is clean!')
        conn.close()
        exit(0)
    
    print(f'Found {len(users)} users to delete:\n')
    for user in users:
        print(f'  👤 {user[1]} ({user[2]}) - Created: {user[3].strftime("%Y-%m-%d")}')
    
    print('\n' + '=' * 60)
    confirm = input('\n⚠️  DELETE ALL THESE USERS? Type "DELETE" to confirm: ')
    
    if confirm != 'DELETE':
        print('\n❌ Cancelled. No users deleted.')
        conn.close()
        exit(0)
    
    print('\n🔥 DELETING...\n')
    
    # Delete in correct order (foreign key constraints)
    
    # 1. Tournament participants
    cur.execute('DELETE FROM tournament_participants WHERE user_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} tournament participations')
    
    # 2. Matches (player1 or player2)
    cur.execute('DELETE FROM matches WHERE player1_id = ANY(%s) OR player2_id = ANY(%s)', (user_ids, user_ids))
    print(f'   ✓ Deleted {cur.rowcount} matches')
    
    # 3. Challenges (created or received)
    cur.execute('DELETE FROM challenges WHERE creator_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} challenges')
    
    # 4. Posts
    cur.execute('DELETE FROM posts WHERE author_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} posts')
    
    # 5. Comments
    cur.execute('DELETE FROM comments WHERE user_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} comments')
    
    # 6. Club memberships
    cur.execute('DELETE FROM club_members WHERE user_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} club memberships')
    
    # 7. ELO history
    cur.execute('DELETE FROM elo_history WHERE user_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} ELO history records')
    
    # 8. Notifications
    cur.execute('DELETE FROM notifications WHERE user_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} notifications')
    
    # 9. Device tokens
    cur.execute('DELETE FROM device_tokens WHERE user_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} device tokens')
    
    # 10. User preferences
    cur.execute('DELETE FROM user_preferences WHERE user_id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} user preferences')
    
    # 11. Finally, delete users
    cur.execute('DELETE FROM users WHERE id = ANY(%s)', (user_ids,))
    print(f'   ✓ Deleted {cur.rowcount} users')
    
    # COMMIT
    conn.commit()
    
    print('\n' + '=' * 60)
    print(f'\n✅ SUCCESS! Deleted {len(users)} demo users and ALL their data')
    print('   Database is now CLEAN for production! 🚀')

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR: {e}')
    print('   Transaction rolled back. No changes made.')

finally:
    cur.close()
    conn.close()
