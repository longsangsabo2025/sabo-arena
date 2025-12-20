"""
Delete test accounts from @saboarena.com
Keep admin accounts: admin@saboarena.com, losa_admin@saboarena.com
"""
import psycopg2
import json
import sys

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False
cur = conn.cursor()

print('🗑️  DELETE TEST ACCOUNTS')
print('=' * 70)

try:
    # Preview what will be deleted
    print('\n👥 Test accounts to DELETE:')
    cur.execute("""
        SELECT display_name, username, email, rank, elo_rating
        FROM users 
        WHERE email ILIKE '%saboarena.com%'
        AND email NOT IN ('admin@saboarena.com', 'losa_admin@saboarena.com')
        ORDER BY created_at
    """)
    
    test_users = cur.fetchall()
    print(f'\nFound {len(test_users)} test accounts:\n')
    for name, username, email, rank, elo in test_users:
        name_str = name or 'NO_NAME'
        username_str = username or 'no_username'
        rank_str = rank or 'NO_RANK'
        print(f'  • {name_str:20s} @{username_str:15s} ({email})')
    
    print('\n✅ WILL KEEP:')
    print('  • admin@saboarena.com (Khanh Lê)')
    print('  • losa_admin@saboarena.com (Tuss Roku)')
    
    # Get UUIDs for deletion
    cur.execute("""
        SELECT id FROM users 
        WHERE email ILIKE '%saboarena.com%'
        AND email NOT IN ('admin@saboarena.com', 'losa_admin@saboarena.com')
    """)
    user_ids = [str(row[0]) for row in cur.fetchall()]
    
    if not user_ids:
        print('\n❌ No users to delete!')
        sys.exit(0)
    
    print(f'\n⚠️  Type "DELETE {len(user_ids)} USERS" to confirm: ', end='')
    confirm = input()
    
    if confirm != f"DELETE {len(user_ids)} USERS":
        print('\n❌ Aborted.')
        sys.exit(0)
    
    print('\n🔄 Deleting...\n')
    
    # Delete related data
    print('  [1/5] Tournament participants...')
    cur.execute(f"""
        DELETE FROM tournament_participants 
        WHERE user_id = ANY(%s::uuid[])
    """, (user_ids,))
    print(f'        ✓ {cur.rowcount} records')
    
    print('  [2/5] Matches...')
    cur.execute(f"""
        DELETE FROM matches 
        WHERE player1_id = ANY(%s::uuid[]) OR player2_id = ANY(%s::uuid[])
    """, (user_ids, user_ids))
    print(f'        ✓ {cur.rowcount} records')
    
    print('  [3/5] Club members...')
    cur.execute(f"""
        DELETE FROM club_members 
        WHERE user_id = ANY(%s::uuid[])
    """, (user_ids,))
    print(f'        ✓ {cur.rowcount} records')
    
    print('  [4/5] ELO history...')
    cur.execute(f"""
        DELETE FROM elo_history 
        WHERE user_id = ANY(%s::uuid[])
    """, (user_ids,))
    print(f'        ✓ {cur.rowcount} records')
    
    print('  [5/5] Users...')
    cur.execute(f"""
        DELETE FROM users 
        WHERE id = ANY(%s::uuid[])
    """, (user_ids,))
    deleted_users = cur.rowcount
    print(f'        ✓ {deleted_users} users')
    
    # Commit
    conn.commit()
    print('\n✅ COMMIT - All changes saved')
    
    # Verify
    cur.execute("""
        SELECT COUNT(*) FROM users 
        WHERE email ILIKE '%saboarena.com%'
    """)
    remaining = cur.fetchone()[0]
    print(f'\n📊 Remaining @saboarena.com users: {remaining}')
    
    cur.execute("""
        SELECT display_name, email FROM users 
        WHERE email ILIKE '%saboarena.com%'
    """)
    for name, email in cur.fetchall():
        print(f'  ✅ {name or "NO_NAME"} ({email})')
    
    print('\n' + '=' * 70)

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR - ROLLBACK: {e}')
    sys.exit(1)
finally:
    conn.close()
