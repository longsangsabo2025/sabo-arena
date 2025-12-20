"""
Verify account settings features schema
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🔍 Verifying Account Settings Schema')
print('=' * 70)

# Check tables
print('\n📊 Tables:')
tables = ['user_sessions', 'user_privacy_settings', 'user_blocks', 'deleted_accounts_log']
for table in tables:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        count = cur.fetchone()[0]
        print(f'  ✅ {table}: {count} rows')
    except Exception as e:
        print(f'  ❌ {table}: NOT FOUND')

# Check users table columns
print('\n🔍 Users table new columns:')
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'users' 
    AND column_name IN (
        'totp_secret', 'totp_enabled', 'totp_backup_codes', 'totp_enabled_at',
        'is_deactivated', 'deactivated_at', 'deactivation_reason'
    )
    ORDER BY column_name
""")
results = cur.fetchall()
if results:
    for col, dtype, nullable in results:
        print(f'  ✅ {col} ({dtype}) - nullable: {nullable}')
else:
    print('  ❌ No new columns found')

# Check RLS policies
print('\n🔐 RLS Policies:')
for table in tables:
    cur.execute(f"""
        SELECT COUNT(*) 
        FROM pg_policies 
        WHERE tablename = '{table}'
    """)
    count = cur.fetchone()[0]
    print(f'  {table}: {count} policies')

print('\n' + '=' * 70)
conn.close()
