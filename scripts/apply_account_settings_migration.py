"""
Apply account settings features migration to Supabase
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False
cur = conn.cursor()

print('🚀 Applying Account Settings Features Migration')
print('=' * 70)

try:
    # Read migration file
    with open('sql_migrations/account_settings_features.sql', 'r', encoding='utf-8') as f:
        migration_sql = f.read()
    
    print('\n📝 Executing migration...\n')
    
    # Execute migration
    cur.execute(migration_sql)
    
    # Commit
    conn.commit()
    print('\n✅ Migration applied successfully!')
    
    # Verify tables
    print('\n📊 Verifying tables:')
    
    tables_to_check = [
        'user_sessions',
        'user_privacy_settings',
        'user_blocks',
        'deleted_accounts_log'
    ]
    
    for table in tables_to_check:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        count = cur.fetchone()[0]
        print(f'  ✓ {table}: {count} rows')
    
    # Check new columns in users table
    print('\n🔍 New columns in users table:')
    cur.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name IN (
            'totp_secret', 'totp_enabled', 'totp_backup_codes', 
            'is_deactivated', 'deactivated_at'
        )
    """)
    for col, dtype in cur.fetchall():
        print(f'  ✓ {col} ({dtype})')
    
    print('\n' + '=' * 70)
    print('🎉 Ready to implement features!')

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR - ROLLBACK: {e}')
    import traceback
    traceback.print_exc()
finally:
    conn.close()
