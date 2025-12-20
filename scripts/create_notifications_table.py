#!/usr/bin/env python3
"""
🚀 ELON MODE: Create notifications table
Run this migration to enable direct user notifications
"""

import os
import sys
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def main():
    print("🚀 Creating notifications table...")
    
    # Read SQL file
    sql_file = 'sql_migrations/20250219_create_notifications_table.sql'
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql = f.read()
    
    try:
        # Execute SQL (note: Supabase Python client doesn't have direct SQL execution)
        # You need to run this SQL manually in Supabase SQL Editor
        print("\n📋 SQL to execute:")
        print("=" * 80)
        print(sql)
        print("=" * 80)
        print("\n⚠️ MANUAL STEP REQUIRED:")
        print("1. Open Supabase Dashboard → SQL Editor")
        print("2. Copy the SQL above")
        print("3. Paste and run it")
        print("\nOr run via psql:")
        print(f"psql {SUPABASE_URL} < {sql_file}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
