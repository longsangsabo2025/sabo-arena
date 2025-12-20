"""
Check if K+ or I+ still exists in database
"""
import psycopg2
import json
import sys

try:
    env = json.load(open('env.json'))
    conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
    cur = conn.cursor()
except Exception as e:
    print(f'❌ Connection error: {e}')
    sys.exit(1)

print('🔍 Checking for K+ and I+ in database\n')

# Check users table
cur.execute("""
    SELECT display_name, rank, elo_rating, wins, losses 
    FROM users 
    WHERE rank IN ('K+', 'I+')
    ORDER BY elo_rating DESC
    LIMIT 20
""")

kplus_users = cur.fetchall()
if kplus_users:
    print(f'❌ Found {len(kplus_users)} users with K+ or I+ rank:\n')
    for name, rank, elo, wins, losses in kplus_users:
        name_str = name if name else 'NO_NAME'
        elo_str = str(elo) if elo else '0'
        wins_str = str(wins) if wins else '0'
        losses_str = str(losses) if losses else '0'
        print(f'  • {name_str:20s} {rank:5s} ELO:{elo_str:5s} W:{wins_str:3s} L:{losses_str:3s}')
else:
    print('✅ No K+ or I+ ranks found in users table')

# Check all unique ranks
print('\n📊 All unique ranks in database:')
cur.execute('SELECT DISTINCT rank FROM users WHERE rank IS NOT NULL ORDER BY rank')
all_ranks = [r[0] for r in cur.fetchall()]
print(f'  {", ".join(all_ranks)}')

conn.close()
