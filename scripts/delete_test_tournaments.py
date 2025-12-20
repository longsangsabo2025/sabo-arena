"""
Delete test tournaments: test1, test2
"""
import psycopg2
import json
import sys

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False
cur = conn.cursor()

print('🗑️  DELETE TEST TOURNAMENTS')
print('=' * 70)

try:
    # Preview
    print('\n🏆 Test tournaments to DELETE:')
    cur.execute("""
        SELECT id, title, status, current_participants, club_id, created_at::date
        FROM tournaments 
        WHERE title IN ('test1', 'test2')
        ORDER BY created_at
    """)
    
    test_tournaments = cur.fetchall()
    if not test_tournaments:
        print('\n✅ No test tournaments found!')
        conn.close()
        sys.exit(0)
    
    print(f'\nFound {len(test_tournaments)} tournaments:\n')
    tournament_ids = []
    for tid, title, status, participants, club_id, created in test_tournaments:
        tournament_ids.append(str(tid))
        print(f'  • {title:10s} | {status:10s} | {participants} players | Created: {created}')
    
    # Check related data
    cur.execute(f"""
        SELECT COUNT(*) FROM tournament_participants 
        WHERE tournament_id = ANY(%s::uuid[])
    """, (tournament_ids,))
    participants_count = cur.fetchone()[0]
    
    cur.execute(f"""
        SELECT COUNT(*) FROM matches 
        WHERE tournament_id = ANY(%s::uuid[])
    """, (tournament_ids,))
    matches_count = cur.fetchone()[0]
    
    print(f'\n📊 Related data:')
    print(f'  • {participants_count} tournament participants')
    print(f'  • {matches_count} matches')
    
    print(f'\n⚠️  Type "DELETE TOURNAMENTS" to confirm: ', end='')
    confirm = input()
    
    if confirm != "DELETE TOURNAMENTS":
        print('\n❌ Aborted.')
        sys.exit(0)
    
    print('\n🔄 Deleting...\n')
    
    # Delete posts first
    print('  [1/4] Posts linked to tournaments...')
    cur.execute(f"""
        DELETE FROM posts 
        WHERE tournament_id = ANY(%s::uuid[])
    """, (tournament_ids,))
    print(f'        ✓ {cur.rowcount} posts')
    
    # Delete
    print('  [2/4] Tournament participants...')
    cur.execute(f"""
        DELETE FROM tournament_participants 
        WHERE tournament_id = ANY(%s::uuid[])
    """, (tournament_ids,))
    print(f'        ✓ {cur.rowcount} records')
    
    print('  [3/4] Matches...')
    cur.execute(f"""
        DELETE FROM matches 
        WHERE tournament_id = ANY(%s::uuid[])
    """, (tournament_ids,))
    print(f'        ✓ {cur.rowcount} records')
    
    print('  [4/4] Tournaments...')
    cur.execute(f"""
        DELETE FROM tournaments 
        WHERE id = ANY(%s::uuid[])
    """, (tournament_ids,))
    print(f'        ✓ {cur.rowcount} tournaments')
    
    # Commit
    conn.commit()
    print('\n✅ COMMIT - All changes saved')
    
    # Final count
    cur.execute('SELECT COUNT(*) FROM tournaments')
    total = cur.fetchone()[0]
    print(f'\n📊 Total tournaments remaining: {total}')
    
    print('\n' + '=' * 70)

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR - ROLLBACK: {e}')
    sys.exit(1)
finally:
    conn.close()
