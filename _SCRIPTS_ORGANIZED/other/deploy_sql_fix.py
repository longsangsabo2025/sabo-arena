#!/usr/bin/env python3
"""
Deploy Direct Messages RLS Fix to Supabase
This script helps you copy the SQL migration to run in Supabase Dashboard
"""

import os
import pyperclip

def main():
    print("=" * 50)
    print("  Fix Direct Messages RLS Policy")
    print("=" * 50)
    print()
    
    sql_file = os.path.join("supabase", "migrations", "20250114000001_fix_direct_messages_rls.sql")
    
    if not os.path.exists(sql_file):
        print(f"❌ Migration file not found: {sql_file}")
        return
    
    print(f"✅ Migration file found: {sql_file}")
    print()
    
    print("📋 INSTRUCTIONS:")
    print("1. Go to: https://supabase.com/dashboard")
    print("2. Select project: mogjjvscxjwvhtpkrlqr")
    print("3. Click 'SQL Editor' in left sidebar")
    print("4. Click 'New Query'")
    print("5. Paste the SQL and click 'Run' (or press F5)")
    print()
    
    print("=" * 50)
    print("  SQL CONTENT:")
    print("=" * 50)
    print()
    
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
        print(sql_content)
    
    print()
    print("=" * 50)
    print()
    
    # Copy to clipboard
    try:
        pyperclip.copy(sql_content)
        print("✅ SQL automatically copied to clipboard!")
        print("   Now paste it in Supabase SQL Editor")
    except:
        print("⚠️  Could not copy to clipboard automatically")
        print("   Please copy the SQL above manually")
    
    print()
    print("After running the SQL, press 'R' in Flutter terminal to restart app")
    print()

if __name__ == "__main__":
    main()
