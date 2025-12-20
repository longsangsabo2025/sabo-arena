"""
Fix K+ and I+ ranks in database - migrate to 10-rank system
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False
cur = conn.cursor()

print('🔧 Fixing K+ and I+ ranks in database\n')
print('=' * 70)

try:
    # Check before
    cur.execute("SELECT COUNT(*) FROM users WHERE rank IN ('K+', 'I+')")
    before_count = cur.fetchone()[0]
    print(f'Before: {before_count} users with K+ or I+ rank')
    
    # Fix K+ → K
    print('\n  [1/2] K+ → K...')
    cur.execute("UPDATE users SET rank = 'K' WHERE rank = 'K+'")
    kplus_fixed = cur.rowcount
    print(f'        ✓ Fixed {kplus_fixed} users')
    
    # Fix I+ → I  
    print('  [2/2] I+ → I...')
    cur.execute("UPDATE users SET rank = 'I' WHERE rank = 'I+'")
    iplus_fixed = cur.rowcount
    print(f'        ✓ Fixed {iplus_fixed} users')
    
    # Commit
    conn.commit()
    print('\n✅ COMMIT - Changes saved')
    
    # Verify
    cur.execute("SELECT COUNT(*) FROM users WHERE rank IN ('K+', 'I+')")
    after_count = cur.fetchone()[0]
    print(f'\nAfter: {after_count} users with K+ or I+ rank')
    
    # Show all ranks
    cur.execute('SELECT DISTINCT rank FROM users WHERE rank IS NOT NULL ORDER BY rank')
    all_ranks = [r[0] for r in cur.fetchall()]
    print(f'\n✅ Valid ranks only: {", ".join(all_ranks)}')
    
    print('\n' + '=' * 70)

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR - ROLLBACK: {e}')
finally:
    conn.close()
