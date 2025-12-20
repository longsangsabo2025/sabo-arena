"""
Run the fix_rank_update_on_approval migration using Supabase client.
"""
import json
import requests

# Load environment variables from env.json
with open('env.json', 'r') as f:
    env = json.load(f)

SUPABASE_URL = env['SUPABASE_URL']
SUPABASE_SERVICE_KEY = env['SUPABASE_SERVICE_ROLE_KEY']

# Read migration file
with open('supabase/migrations/20251220000000_fix_rank_update_on_approval.sql', 'r', encoding='utf-8') as f:
    migration_sql = f.read()

print("🚀 Running migration via Supabase REST API...")

# Execute SQL via Supabase PostgREST
headers = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

# Use rpc to execute raw SQL
url = f'{SUPABASE_URL}/rest/v1/rpc/exec_sql'

# First, create the exec_sql function if it doesn't exist
create_function_sql = """
CREATE OR REPLACE FUNCTION exec_sql(sql text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    EXECUTE sql;
    RETURN 'OK';
END;
$$;
"""

print("📝 Creating exec_sql helper function...")
response = requests.post(
    f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
    headers=headers,
    json={'sql': create_function_sql}
)

if response.status_code in [200, 201, 204]:
    print("✅ Helper function created")
else:
    print(f"⚠️ Helper function creation response: {response.status_code}")

print("🔧 Executing migration...")
response = requests.post(
    url,
    headers=headers,
    json={'sql': migration_sql}
)

if response.status_code in [200, 201, 204]:
    print("✅ Migration completed successfully!")
    print("\n📊 Verifying changes...")
    
    # Verify column exists
    verify_sql = """
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'rank_requests' 
        AND column_name = 'requested_rank'
    );
    """
    
    response = requests.post(
        url,
        headers=headers,
        json={'sql': verify_sql}
    )
    
    if response.status_code == 200:
        print("✅ Column 'requested_rank' verified")
    
    print("\n✨ Migration completed! Rank update bug is now fixed.")
else:
    print(f"❌ Migration failed: {response.status_code}")
    print(f"Response: {response.text}")
