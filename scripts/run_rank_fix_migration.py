"""
Run the fix_rank_update_on_approval migration to fix the rank update bug.
This fixes the issue where user rank is not updated to requested rank after approval.
"""
import os
import sys
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

# Load environment variables from env.json
import json
with open('env.json', 'r') as f:
    env = json.load(f)
    for key, value in env.items():
        os.environ[key] = value

def run_migration():
    """Run the migration to fix rank update on approval"""
    
    # Get database URL from environment - use transaction pooler
    db_url = os.getenv('SUPABASE_DB_TRANSACTION_URL')
    
    if not db_url:
        print("❌ SUPABASE_DB_TRANSACTION_URL not found in environment")
        sys.exit(1)
    
    print(f"🔗 Connecting to database...")
    
    try:
        # Connect to database
        conn = psycopg2.connect(db_url)
        cursor = conn.cursor()
        
        print("✅ Connected successfully")
        
        # Read migration file
        migration_file = Path(__file__).parent.parent / 'supabase' / 'migrations' / '20251220000001_fix_notification_rank.sql'
        
        if not migration_file.exists():
            print(f"❌ Migration file not found: {migration_file}")
            sys.exit(1)
        
        print(f"📄 Reading migration file: {migration_file}")
        
        with open(migration_file, 'r', encoding='utf-8') as f:
            migration_sql = f.read()
        
        print("🚀 Running migration...")
        
        # Execute migration
        cursor.execute(migration_sql)
        conn.commit()
        
        print("✅ Migration completed successfully!")
        
        # Verify the changes
        print("\n🔍 Verifying changes...")
        
        # Check if column exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT 1 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'rank_requests' 
                AND column_name = 'requested_rank'
            );
        """)
        
        column_exists = cursor.fetchone()[0]
        
        if column_exists:
            print("✅ Column 'requested_rank' exists")
        else:
            print("❌ Column 'requested_rank' not found")
        
        # Check if function exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT 1 
                FROM information_schema.routines 
                WHERE routine_schema = 'public' 
                AND routine_name = 'update_user_rank_on_approval'
            );
        """)
        
        function_exists = cursor.fetchone()[0]
        
        if function_exists:
            print("✅ Function 'update_user_rank_on_approval' exists")
        else:
            print("❌ Function 'update_user_rank_on_approval' not found")
        
        # Check if trigger exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT 1 
                FROM information_schema.triggers 
                WHERE trigger_schema = 'public' 
                AND trigger_name = 'on_rank_request_approved'
            );
        """)
        
        trigger_exists = cursor.fetchone()[0]
        
        if trigger_exists:
            print("✅ Trigger 'on_rank_request_approved' exists")
        else:
            print("❌ Trigger 'on_rank_request_approved' not found")
        
        # Show sample of rank_requests with requested_rank
        cursor.execute("""
            SELECT id, user_id, status, requested_rank, 
                   substring(notes FROM 'Rank mong muốn: ([A-K])') as rank_from_notes
            FROM rank_requests 
            LIMIT 5;
        """)
        
        print("\n📊 Sample rank_requests:")
        for row in cursor.fetchall():
            print(f"  ID: {row[0][:8]}..., Status: {row[2]}, Requested: {row[3]}, From notes: {row[4]}")
        
        cursor.close()
        conn.close()
        
        print("\n✨ All done! The rank update bug should now be fixed.")
        print("\nℹ️  Next time a club approves a rank request:")
        print("   1. The trigger will automatically update the user's rank")
        print("   2. The rank will be set to the requested_rank value")
        print("   3. Notifications will show the correct rank")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    run_migration()
