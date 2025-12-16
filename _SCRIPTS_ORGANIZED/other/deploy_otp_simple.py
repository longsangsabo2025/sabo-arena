"""
Simple OTP Table Deployment Script
Run SQL directly through Supabase REST API
"""

import requests
import os

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', '')

if not SUPABASE_SERVICE_KEY:
    print("❌ SUPABASE_SERVICE_KEY not set")
    print("Get your service role key from Supabase Dashboard > Project Settings > API")
    print("Then run: $env:SUPABASE_SERVICE_KEY='your-key-here'")
    exit(1)

# SQL statements
SQL_STATEMENTS = [
    # Create table
    """
    CREATE TABLE IF NOT EXISTS public.otp_codes (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        phone TEXT NOT NULL,
        otp_code TEXT NOT NULL,
        purpose TEXT NOT NULL DEFAULT 'password_reset',
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        used BOOLEAN DEFAULT FALSE,
        used_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    )
    """,
    
    # Create indexes
    "CREATE INDEX IF NOT EXISTS idx_otp_codes_phone ON public.otp_codes(phone)",
    "CREATE INDEX IF NOT EXISTS idx_otp_codes_expires_at ON public.otp_codes(expires_at)",
    "CREATE INDEX IF NOT EXISTS idx_otp_codes_used ON public.otp_codes(used)",
    
    # Enable RLS
    "ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY",
]

def execute_sql(sql: str):
    """Execute SQL using Supabase REST API"""
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    headers = {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json"
    }
    data = {"sql": sql}
    
    response = requests.post(url, headers=headers, json=data)
    return response

def main():
    print("🚀 Deploying OTP Codes Table...")
    print()
    
    for i, sql in enumerate(SQL_STATEMENTS, 1):
        print(f"📝 Statement {i}/{len(SQL_STATEMENTS)}: {sql[:60]}...")
        
        try:
            response = execute_sql(sql)
            if response.status_code in [200, 201, 204]:
                print("✅ Success")
            else:
                print(f"⚠️  Response: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"❌ Error: {e}")
        
        print()
    
    print("✅ Deployment complete!")
    print()
    print("📋 To verify, run this query in Supabase SQL Editor:")
    print("   SELECT * FROM public.otp_codes;")

if __name__ == '__main__':
    main()
