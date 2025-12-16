#!/usr/bin/env python3
"""
Auto-deploy club_follows table to Supabase
Tự động tạo table và policies cho tính năng follow club
"""

import os
import sys
import json
from supabase import create_client, Client

def load_env_config():
    """Load Supabase config from env.json"""
    try:
        with open('env.json', 'r') as f:
            config = json.load(f)
            return config.get('supabase', {})
    except FileNotFoundError:
        print("❌ env.json not found!")
        return None
    except Exception as e:
        print(f"❌ Error reading env.json: {e}")
        return None

def create_supabase_client():
    """Create Supabase client from env config"""
    config = load_env_config()
    if not config:
        return None
        
    url = config.get('url')
    key = config.get('service_role_key')  # Need service role for admin operations
    
    if not url or not key:
        print("❌ Missing Supabase URL or service_role_key in env.json")
        return None
        
    return create_client(url, key)

def execute_sql_migration(supabase: Client, sql_content: str):
    """Execute SQL migration"""
    try:
        print("🚀 Executing club_follows migration...")
        
        # Execute the SQL migration
        result = supabase.rpc('exec_sql', {'sql': sql_content}).execute()
        
        if result.data:
            print("✅ Migration executed successfully!")
            return True
        else:
            print("❌ Migration failed")
            return False
            
    except Exception as e:
        print(f"❌ Error executing migration: {e}")
        return False

def verify_table_creation(supabase: Client):
    """Verify that club_follows table was created successfully"""
    try:
        print("🔍 Verifying table creation...")
        
        # Try to query the table (should be empty but table should exist)
        result = supabase.table('club_follows').select('*').limit(1).execute()
        
        print("✅ club_follows table verified successfully!")
        print(f"📊 Current records count: {len(result.data)}")
        return True
        
    except Exception as e:
        print(f"❌ Table verification failed: {e}")
        return False

def main():
    """Main deployment function"""
    print("🚀 Starting club_follows table deployment...")
    
    # Read SQL migration file
    migration_file = 'supabase/migrations/20250116000000_create_club_follows.sql'
    if not os.path.exists(migration_file):
        print(f"❌ Migration file not found: {migration_file}")
        sys.exit(1)
        
    with open(migration_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"📄 Loaded migration: {migration_file}")
    
    # Create Supabase client
    supabase = create_supabase_client()
    if not supabase:
        print("❌ Failed to create Supabase client")
        sys.exit(1)
    
    print("✅ Supabase client connected")
    
    # Execute migration using raw SQL approach
    try:
        print("🔧 Executing SQL migration directly...")
        
        # Split SQL into individual statements
        statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
        
        for i, statement in enumerate(statements):
            if statement:
                print(f"📝 Executing statement {i+1}/{len(statements)}...")
                try:
                    # Use the SQL function to execute each statement
                    result = supabase.rpc('exec_sql', {'statement': statement}).execute()
                    print(f"✅ Statement {i+1} executed")
                except Exception as e:
                    print(f"⚠️ Statement {i+1} warning: {e}")
                    # Continue with other statements
        
        print("✅ All statements processed!")
        
    except Exception as e:
        print(f"❌ Migration execution failed: {e}")
        print("🔧 Trying alternative approach...")
        
        # Alternative: Try to create table directly
        try:
            # Create the basic table structure
            create_table_sql = """
            CREATE TABLE IF NOT EXISTS public.club_follows (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                user_id UUID NOT NULL,
                club_id UUID NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(user_id, club_id)
            );
            """
            
            supabase.rpc('exec_sql', {'statement': create_table_sql}).execute()
            print("✅ Basic table structure created")
            
        except Exception as e2:
            print(f"❌ Alternative approach also failed: {e2}")
    
    # Verify table creation
    if verify_table_creation(supabase):
        print("\n🎉 Club follows table deployment completed successfully!")
        print("💡 Now you can test the follow/unfollow functionality in the app")
    else:
        print("\n❌ Deployment verification failed")
        
    return True

if __name__ == '__main__':
    main()