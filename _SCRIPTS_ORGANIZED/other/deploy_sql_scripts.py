#!/usr/bin/env python3
"""
Auto-deploy Direct Messages RLS Fix to Supabase
Automatically runs the SQL migration using service key
"""

import os
import json
import requests

def main():
    print("=" * 60)
    print("  Auto-Deploy: Fix Direct Messages RLS Policy")
    print("=" * 60)
    print()
    
    # Read environment config
    env_file = "env.json"
    if not os.path.exists(env_file):
        print(f"❌ Config file not found: {env_file}")
        print("   Please create env.json with Supabase credentials")
        return
    
    with open(env_file, 'r') as f:
        env = json.load(f)
    
    supabase_url = env.get('SUPABASE_URL')
    service_key = env.get('SUPABASE_SERVICE_KEY') or env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not supabase_url or not service_key:
        print("❌ Missing Supabase credentials in env.json")
        print("   Required: SUPABASE_URL and SUPABASE_SERVICE_KEY")
        return
    
    print(f"✅ Found Supabase config")
    print(f"   URL: {supabase_url}")
    print()
    
    # Read SQL migration
    sql_file = os.path.join("supabase", "migrations", "20250114000001_fix_direct_messages_rls.sql")
    
    if not os.path.exists(sql_file):
        print(f"❌ Migration file not found: {sql_file}")
        return
    
    print(f"✅ Found migration file: {sql_file}")
    print()
    
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    # Execute SQL using Supabase Management API
    print("� Executing SQL migration...")
    print("-" * 60)
    
    # Split SQL into individual statements
    statements = [s.strip() for s in sql_content.split(';') if s.strip() and not s.strip().startswith('--')]
    
    print(f"📝 Found {len(statements)} SQL statements to execute")
    print()
    
    success_count = 0
    failed_count = 0
    
    # Execute each statement using REST API
    headers = {
        'apikey': service_key,
        'Authorization': f'Bearer {service_key}',
        'Content-Type': 'application/json'
    }
    
    for i, statement in enumerate(statements, 1):
        if not statement:
            continue
            
        print(f"  [{i}/{len(statements)}] Executing... ", end='', flush=True)
        
        try:
            # Try to execute via REST API query endpoint
            response = requests.post(
                f'{supabase_url}/rest/v1/rpc/exec',
                headers=headers,
                json={'query': statement},
                timeout=30
            )
            
            if response.status_code == 200:
                print("✅")
                success_count += 1
            else:
                print(f"⚠️ Status {response.status_code}")
                failed_count += 1
                
        except Exception as e:
            print(f"❌ {str(e)[:50]}")
            failed_count += 1
    
    print()
    print("-" * 60)
    
    if failed_count > 0:
        print(f"⚠️  Some statements failed ({failed_count}/{len(statements)})")
        print()
        print("📋 Please run this SQL manually in Supabase Dashboard:")
        print()
        print("📍 Steps:")
        print("   1. Go to: https://supabase.com/dashboard")
        print("   2. Select project: mogjjvscxjwvhtpkrlqr")
        print("   3. Click 'SQL Editor' > 'New Query'")
        print("   4. Copy SQL from file: supabase/migrations/20250114000001_fix_direct_messages_rls.sql")
        print("   5. Paste and click 'Run' (F5)")
        print()
        return
    
    print("✅ All SQL statements executed successfully!")
    print()
    print("📝 Changes applied:")
    print("   - Made chat_rooms.club_id nullable")
    print("   - Updated INSERT policy for direct messages")
    print("   - Updated SELECT policy to include direct messages")  
    print("   - Updated chat_room_members policies")
    print("   - Added index on chat_rooms.type")
    print()
    
    print("=" * 60)
    print("✅ Migration completed successfully!")
    print()
    print("🎯 Next steps:")
    print("   1. Press 'R' in Flutter terminal to restart app")
    print("   2. Test 'Nhắn tin' button in user profile")
    print("   3. Should open chat screen directly")
    print()

if __name__ == "__main__":
    main()
