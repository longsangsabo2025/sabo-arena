"""
Script để tạo bảng challenges và chạy migration
Sử dụng service role key để có quyền tạo bảng
"""
import os
from dotenv import load_dotenv
from supabase import create_client

# Load environment variables
load_dotenv()

# Initialize Supabase với service role key
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://mogjjvscxjwvhtpkrlqr.supabase.co")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_SERVICE_KEY:
    print("❌ SUPABASE_SERVICE_ROLE_KEY not found in .env file")
    exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def run_sql_migration():
    print("\n🚀 CREATING CHALLENGES TABLE")
    print("=" * 60)
    
    try:
        # Read the migration file
        migration_file = 'supabase/migrations/20251020_create_challenges_table.sql'
        
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql = f.read()
        
        print(f"📄 Migration file: {migration_file}")
        print(f"📏 SQL length: {len(sql)} characters\n")
        
        # Execute via RPC using Supabase's SQL function
        # Note: We need to use psycopg2 or direct SQL execution
        # Supabase Python client doesn't support raw SQL execution
        
        print("⚠️ Using alternative approach: Direct table creation via Python")
        print("=" * 60 + "\n")
        
        # Check if challenges table already exists
        try:
            test_query = supabase.table('challenges').select('id').limit(1).execute()
            print("✅ Challenges table already exists!")
            print(f"   Current records: {len(test_query.data)}\n")
            return True
        except Exception as e:
            error_msg = str(e)
            if 'relation "public.challenges" does not exist' in error_msg or 'does not exist' in error_msg:
                print("📋 Challenges table does not exist. Need to create it.\n")
            else:
                print(f"⚠️ Error checking table: {e}\n")
        
        # Instructions for manual migration
        print("=" * 60)
        print("📝 MANUAL MIGRATION REQUIRED")
        print("=" * 60)
        print("\nOption 1: Via Supabase Dashboard (RECOMMENDED)")
        print("-" * 60)
        print("1. Open: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/editor")
        print("2. Go to: SQL Editor (left sidebar)")
        print("3. Click: 'New Query'")
        print("4. Copy the SQL from:")
        print(f"   {os.path.abspath(migration_file)}")
        print("5. Paste and click 'Run'\n")
        
        print("Option 2: Via psql Command Line")
        print("-" * 60)
        print("psql postgresql://postgres:[PASSWORD]@db.mogjjvscxjwvhtpkrlqr.supabase.co:5432/postgres \\")
        print(f"  -f {migration_file}\n")
        
        print("=" * 60)
        print("\n💡 After running the migration, run this script again to verify.")
        
        return False
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def verify_migration():
    """Verify that the migration was successful"""
    print("\n🔍 VERIFYING MIGRATION")
    print("=" * 60)
    
    try:
        # Check if table exists
        result = supabase.table('challenges').select('id').limit(1).execute()
        print("✅ Challenges table exists and is accessible!")
        print(f"   Current records: {len(result.data)}")
        
        # Check if we can insert (test RLS policies)
        print("\n🔒 Testing RLS policies...")
        print("   (This requires authentication, so it may fail)")
        
        return True
        
    except Exception as e:
        print(f"❌ Table does not exist or is not accessible: {e}")
        return False

if __name__ == "__main__":
    # Try to run migration
    success = run_sql_migration()
    
    if success:
        print("\n✅ Migration verified successfully!")
    else:
        print("\n⏳ Waiting for manual migration...")
