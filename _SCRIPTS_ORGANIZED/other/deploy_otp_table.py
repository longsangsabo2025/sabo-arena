"""
Auto-deploy OTP Codes table to Supabase
Creates table for SMS/Phone OTP verification
"""

import os
from supabase import create_client, Client

# Supabase credentials
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', '')

if not SUPABASE_SERVICE_KEY:
    print("❌ SUPABASE_SERVICE_KEY environment variable not set")
    print("Please run:")
    print('$env:SUPABASE_SERVICE_KEY="your-service-role-key"')
    exit(1)

# Initialize Supabase client with service role key
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def read_sql_file(filename: str) -> str:
    """Read SQL file content"""
    with open(filename, 'r', encoding='utf-8') as f:
        return f.read()

def execute_sql(sql: str) -> bool:
    """Execute SQL statement"""
    try:
        # Split SQL into individual statements
        statements = [s.strip() for s in sql.split(';') if s.strip()]
        
        for statement in statements:
            if not statement:
                continue
                
            print(f"📝 Executing: {statement[:80]}...")
            
            # Execute via Supabase RPC or direct SQL
            result = supabase.rpc('exec_sql', {'sql': statement}).execute()
            
            print(f"✅ Success")
            
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("🚀 Deploying OTP Codes Table...")
    print(f"📡 Supabase URL: {SUPABASE_URL}")
    print()
    
    # Read SQL file
    sql_file = 'CREATE_OTP_CODES_TABLE.sql'
    print(f"📖 Reading {sql_file}...")
    sql = read_sql_file(sql_file)
    
    # Execute SQL
    print("⚡ Executing SQL migration...")
    success = execute_sql(sql)
    
    if success:
        print()
        print("✅ OTP Codes table deployed successfully!")
        print()
        print("📋 Next steps:")
        print("1. Test phone OTP in the app")
        print("2. Check DEBUG console for OTP codes (development mode)")
        print("3. Integrate SMS gateway for production (Twilio, ESMS, etc.)")
    else:
        print()
        print("❌ Deployment failed. Please check errors above.")

if __name__ == '__main__':
    main()
