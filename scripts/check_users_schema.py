"""
Check USERS table schema for SPA, stats, notifications
"""
import psycopg2
import json
import sys

try:
    env = json.load(open('env.json'))
    print('✓ Loaded env.json')
    conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
    print('✓ Connected to Supabase\n')
    cur = conn.cursor()
except Exception as e:
    print(f'❌ Error: {e}')
    sys.exit(1)

print('🔍 USERS TABLE - Full Schema Check\n')
print('=' * 70)

# Get ALL columns in users table
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'users' 
    ORDER BY ordinal_position
""")

users_columns = cur.fetchall()
print(f'Total columns: {len(users_columns)}\n')

for col, dtype, nullable in users_columns:
    null_text = '✓' if nullable == 'YES' else '✗'
    print(f'  {col:30s} {dtype:20s} Null:{null_text}')

# Check specific column types
print('\n' + '=' * 70)
print('\n💰 SPA/Balance/Coins columns:')
spa_found = False
for col, dtype, _ in users_columns:
    if any(keyword in col.lower() for keyword in ['spa', 'balance', 'coin', 'credit']):
        print(f'  ✓ {col} ({dtype})')
        spa_found = True
if not spa_found:
    print('  ❌ NONE FOUND')

print('\n📊 Win/Loss/Match Statistics columns:')
stats_found = False
for col, dtype, _ in users_columns:
    if any(keyword in col.lower() for keyword in ['win', 'loss', 'match', 'played', 'total']):
        print(f'  ✓ {col} ({dtype})')
        stats_found = True
if not stats_found:
    print('  ❌ NONE FOUND')

# Check for separate statistics tables
print('\n' + '=' * 70)
print('\n🔍 Other tables with user statistics:')
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND (table_name LIKE '%stat%' 
         OR table_name LIKE '%member%stat%'
         OR table_name LIKE '%user%stat%'
         OR table_name LIKE '%player%stat%')
    ORDER BY table_name
""")
stat_tables = cur.fetchall()
if stat_tables:
    for table in stat_tables:
        print(f'  • {table[0]}')
        # Show columns
        cur.execute(f"""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = '{table[0]}' 
            ORDER BY ordinal_position 
            LIMIT 10
        """)
        for col, dtype in cur.fetchall():
            print(f'      - {col} ({dtype})')
else:
    print('  ❌ NONE FOUND')

# Check notifications table
print('\n' + '=' * 70)
print('\n🔔 NOTIFICATIONS table:')
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'notifications' 
    ORDER BY ordinal_position
""")
notif_cols = cur.fetchall()
if notif_cols:
    for col, dtype in notif_cols:
        print(f'  • {col} ({dtype})')
else:
    print('  ❌ Table not found')

print('\n' + '=' * 70)
print()

conn.close()
