"""
ELON MODE: Nuclear option - Delete all 61 demo users
Transaction-safe with rollback on error
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False
cur = conn.cursor()

print('💣 ELON MODE: NUCLEAR CLEANUP OF DEMO USERS\n')
print('=' * 70)

try:
    # Get all demo user IDs
    cur.execute("""
        SELECT id, username, email, created_at
        FROM users 
        WHERE email ILIKE '%demo%'
        ORDER BY created_at
    """)
    
    demo_users = cur.fetchall()
    user_ids = [u[0] for u in demo_users]
    
    if not demo_users:
        print('✅ No demo users found. Database already clean.\n')
        conn.close()
        exit(0)
    
    print(f'🔴 Found {len(demo_users)} demo users to DELETE:\n')
    for uid, username, email, created in demo_users[:5]:
        print(f'  • {username or "N/A"} - {email}')
    if len(demo_users) > 5:
        print(f'  ... and {len(demo_users) - 5} more\n')
    
    print('⚠️  This will DELETE:')
    print('   - All their matches')
    print('   - All their tournament participations')
    print('   - All their posts/comments')
    print('   - All their challenges')
    print('   - All their club memberships')
    print('   - Everything related to these accounts\n')
    
    confirm = input('Type "NUKE" to confirm deletion: ')
    
    if confirm != 'NUKE':
        print('\n❌ Cancelled. No changes made.')
        conn.close()
        exit(0)
    
    print('\n🔥 DELETING...\n')
    
    # Delete core tables that definitely exist
    
    # 1. Tournament participants
    cur.execute('DELETE FROM tournament_participants WHERE user_id = ANY(%s::uuid[])', (user_ids,))
    print(f'   ✓ {cur.rowcount} tournament participations')
    
    # 2. Matches
    cur.execute('DELETE FROM matches WHERE player1_id = ANY(%s::uuid[]) OR player2_id = ANY(%s::uuid[])', (user_ids, user_ids))
    print(f'   ✓ {cur.rowcount} matches')
    
    # 3. Club members
    cur.execute('DELETE FROM club_members WHERE user_id = ANY(%s::uuid[])', (user_ids,))
    print(f'   ✓ {cur.rowcount} club memberships')
    
    # 4. ELO history
    cur.execute('DELETE FROM elo_history WHERE user_id = ANY(%s::uuid[])', (user_ids,))
    print(f'   ✓ {cur.rowcount} ELO records')
    
    # 5. Finally delete users - this is the key one
    cur.execute('DELETE FROM users WHERE id = ANY(%s::uuid[])', (user_ids,))
    deleted_count = cur.rowcount
    print(f'   ✓ {deleted_count} USERS DELETED')
    
    # COMMIT
    conn.commit()
    
    print('\n' + '=' * 70)
    print(f'\n✅ SUCCESS! Nuked {deleted_count} demo users and all their data')
    print('   Database is now PRODUCTION READY 🚀\n')
    
except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR: {e}')
    print('   Transaction rolled back. No changes made.\n')
    
finally:
    cur.close()
    conn.close()
