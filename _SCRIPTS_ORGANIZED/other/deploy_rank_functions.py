"""
Deploy Rank Change Request Functions to Supabase
Fixes: approve_rank_request function not found error
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    raise Exception("Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in .env")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print("=" * 80)
print("DEPLOYING RANK CHANGE REQUEST FUNCTIONS")
print("=" * 80)

# Read the SQL file
sql_file_path = 'scripts/rank_change_request_system.sql'

try:
    with open(sql_file_path, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"\n✅ Read SQL file: {sql_file_path}")
    print(f"📄 File size: {len(sql_content)} characters\n")
    
    # Split by function creation statements
    functions = []
    current_function = []
    in_function = False
    
    for line in sql_content.split('\n'):
        if 'CREATE OR REPLACE FUNCTION' in line:
            if current_function:
                functions.append('\n'.join(current_function))
            current_function = [line]
            in_function = True
        elif in_function:
            current_function.append(line)
            if line.strip() == '$$;':
                in_function = False
        elif not in_function and line.strip().startswith('GRANT EXECUTE'):
            current_function.append(line)
    
    if current_function:
        functions.append('\n'.join(current_function))
    
    print(f"📋 Found {len(functions)} function blocks to deploy\n")
    
    # Deploy each function
    success_count = 0
    error_count = 0
    
    for i, func_sql in enumerate(functions, 1):
        if not func_sql.strip():
            continue
            
        # Extract function name
        func_name = "Unknown"
        for line in func_sql.split('\n'):
            if 'CREATE OR REPLACE FUNCTION' in line:
                parts = line.split('FUNCTION')
                if len(parts) > 1:
                    func_name = parts[1].split('(')[0].strip()
                break
        
        print(f"\n{'=' * 80}")
        print(f"Deploying function {i}: {func_name}")
        print(f"{'=' * 80}")
        
        try:
            # Execute SQL
            response = supabase.rpc('exec_sql', {'query': func_sql}).execute()
            print(f"✅ Successfully deployed: {func_name}")
            success_count += 1
        except Exception as e:
            print(f"❌ Error deploying {func_name}: {e}")
            error_count += 1
            
            # Try direct execution via postgrest
            try:
                print(f"🔄 Retrying with direct SQL execution...")
                
                # For Supabase, we need to use the REST API to execute SQL
                # This is a workaround since Supabase client doesn't have direct SQL execution
                import requests
                
                headers = {
                    'apikey': SUPABASE_SERVICE_KEY,
                    'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
                    'Content-Type': 'application/json'
                }
                
                # Note: This requires postgres extensions enabled
                # Alternative: Use Supabase Dashboard SQL Editor manually
                print(f"⚠️ Please execute this function manually in Supabase Dashboard:")
                print(f"\nFunction SQL:\n{func_sql[:200]}...\n")
                
            except Exception as retry_error:
                print(f"❌ Retry also failed: {retry_error}")
    
    print("\n" + "=" * 80)
    print("DEPLOYMENT SUMMARY")
    print("=" * 80)
    print(f"✅ Success: {success_count}")
    print(f"❌ Errors:  {error_count}")
    print(f"📊 Total:   {len(functions)}")
    
    if error_count > 0:
        print("\n⚠️ MANUAL DEPLOYMENT REQUIRED")
        print("=" * 80)
        print("Please go to Supabase Dashboard > SQL Editor and execute:")
        print(f"File: {sql_file_path}")
        print("\nOr copy-paste the entire SQL file content into the SQL editor.")
    else:
        print("\n🎉 All functions deployed successfully!")
    
except FileNotFoundError:
    print(f"❌ SQL file not found: {sql_file_path}")
    print("Please make sure the file exists.")
except Exception as e:
    print(f"❌ Unexpected error: {e}")

print("\n" + "=" * 80)
print("NEXT STEPS")
print("=" * 80)
print("1. Verify functions in Supabase Dashboard > Database > Functions")
print("2. Test the rank approval flow in the app")
print("3. Check for any RLS policy issues")
print("=" * 80)
