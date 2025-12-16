#!/usr/bin/env python3
"""
Simple Primary Key Fix
Directly add primary keys to all tables that need them
"""

import requests
import json

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

def execute_sql(sql):
    """Execute SQL using custom function"""
    try:
        headers = {
            'Authorization': f'Bearer {SERVICE_KEY}',
            'Content-Type': 'application/json',
            'apikey': SERVICE_KEY
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/execute_sql",
            headers=headers,
            json={'sql_query': sql}
        )
        if response.status_code == 200:
            result = response.json()
            if isinstance(result, dict) and 'error' in result:
                return False, result['error']
            return True, result
        else:
            return False, f"HTTP {response.status_code}: {response.text}"
    except Exception as e:
        return False, f"Exception: {str(e)}"

def main():
    print("="*80)
    print("🔑 SIMPLE PRIMARY KEY FIXER")
    print("="*80)
    
    # Tables that need primary keys based on previous analysis
    tables_to_fix = [
        'announcements',
        'comments', 
        'matches',
        'notification_preferences',
        'post_likes',
        'tournament_participants',
        'user_achievements'
    ]
    
    print(f"🔧 Adding primary keys to {len(tables_to_fix)} tables...")
    
    success_count = 0
    
    for table in tables_to_fix:
        print(f"\n📝 Processing {table}...")
        
        # Add id column as primary key
        sql = f"""
        ALTER TABLE public.{table} 
        ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
        """
        
        success, result = execute_sql(sql)
        if success:
            print(f"  ✅ Added primary key to {table}")
            success_count += 1
            
            # Also add timestamps
            timestamp_sql = f"""
            ALTER TABLE public.{table} 
            ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
            ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
            """
            
            ts_success, ts_result = execute_sql(timestamp_sql)
            if ts_success:
                print(f"  ✅ Added timestamps to {table}")
            else:
                print(f"  ⚠️  Timestamps warning for {table}: {ts_result}")
                
        else:
            print(f"  ❌ Failed to add primary key to {table}: {result}")
    
    print("\n" + "="*80)
    print("📊 RESULTS")
    print("="*80)
    print(f"✅ Primary keys added: {success_count}/{len(tables_to_fix)}")
    
    if success_count == len(tables_to_fix):
        print("🎉 ALL TABLES NOW HAVE PRIMARY KEYS!")
        print("\n🚀 Next: python verify_migration.py")
    else:
        print("⚠️  Some tables still need manual fixing")

if __name__ == "__main__":
    main()