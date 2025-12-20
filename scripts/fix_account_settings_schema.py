"""
Fix database schema issues for account settings
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False
cur = conn.cursor()

print('🔧 Fixing Account Settings Schema Issues')
print('=' * 70)

try:
    # Fix 1: Rename user_blocks columns to match service expectations
    print('\n📝 Renaming user_blocks columns...')
    
    # Drop existing foreign keys
    cur.execute("""
        ALTER TABLE user_blocks 
        DROP CONSTRAINT IF EXISTS user_blocks_blocker_id_fkey,
        DROP CONSTRAINT IF EXISTS user_blocks_blocked_id_fkey;
    """)
    
    # Rename columns
    cur.execute("""
        ALTER TABLE user_blocks 
        RENAME COLUMN blocker_id TO blocker_user_id;
    """)
    cur.execute("""
        ALTER TABLE user_blocks 
        RENAME COLUMN blocked_id TO blocked_user_id;
    """)
    
    # Recreate foreign keys
    cur.execute("""
        ALTER TABLE user_blocks 
        ADD CONSTRAINT user_blocks_blocker_user_id_fkey 
        FOREIGN KEY (blocker_user_id) REFERENCES users(id) ON DELETE CASCADE;
    """)
    cur.execute("""
        ALTER TABLE user_blocks 
        ADD CONSTRAINT user_blocks_blocked_user_id_fkey 
        FOREIGN KEY (blocked_user_id) REFERENCES users(id) ON DELETE CASCADE;
    """)
    
    # Update constraint
    cur.execute("""
        ALTER TABLE user_blocks 
        DROP CONSTRAINT IF EXISTS no_self_block,
        DROP CONSTRAINT IF EXISTS unique_block;
    """)
    cur.execute("""
        ALTER TABLE user_blocks 
        ADD CONSTRAINT no_self_block CHECK (blocker_user_id != blocked_user_id),
        ADD CONSTRAINT unique_block UNIQUE (blocker_user_id, blocked_user_id);
    """)
    
    print('  ✅ user_blocks columns renamed')
    
    # Fix 2: Update indexes
    print('\n📝 Updating indexes...')
    cur.execute("""
        DROP INDEX IF EXISTS idx_user_blocks_blocker;
        DROP INDEX IF EXISTS idx_user_blocks_blocked;
    """)
    cur.execute("""
        CREATE INDEX idx_user_blocks_blocker ON user_blocks(blocker_user_id);
        CREATE INDEX idx_user_blocks_blocked ON user_blocks(blocked_user_id);
    """)
    print('  ✅ Indexes updated')
    
    # Fix 3: Update RLS policies
    print('\n📝 Updating RLS policies...')
    cur.execute("""
        DROP POLICY IF EXISTS "Users can view their blocks" ON user_blocks;
        DROP POLICY IF EXISTS "Users can create blocks" ON user_blocks;
        DROP POLICY IF EXISTS "Users can delete their blocks" ON user_blocks;
    """)
    cur.execute("""
        CREATE POLICY "Users can view their blocks"
            ON user_blocks FOR SELECT
            USING (auth.uid() = blocker_user_id);

        CREATE POLICY "Users can create blocks"
            ON user_blocks FOR INSERT
            WITH CHECK (auth.uid() = blocker_user_id);

        CREATE POLICY "Users can delete their blocks"
            ON user_blocks FOR DELETE
            USING (auth.uid() = blocker_user_id);
    """)
    print('  ✅ RLS policies updated')
    
    # Fix 4: Rename user_sessions column for consistency
    print('\n📝 Checking user_sessions columns...')
    cur.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'user_sessions' AND column_name = 'reason'
    """)
    if cur.fetchone():
        cur.execute("ALTER TABLE user_sessions RENAME COLUMN reason TO block_reason")
        print('  ✅ user_sessions.reason renamed to block_reason')
    
    # Commit all changes
    conn.commit()
    print('\n✅ All schema fixes applied successfully!')
    
    # Verify
    print('\n📊 Verification:')
    cur.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'user_blocks'
        ORDER BY ordinal_position
    """)
    print('  user_blocks columns:')
    for (col,) in cur.fetchall():
        print(f'    • {col}')

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR - ROLLBACK: {e}')
    import traceback
    traceback.print_exc()
finally:
    conn.close()

print('\n' + '=' * 70)
