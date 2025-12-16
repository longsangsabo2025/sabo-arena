#!/usr/bin/env python3
"""
Deploy SQL to Supabase - Simple version
Opens Supabase SQL Editor and copies SQL to clipboard
"""

import os
import webbrowser
import pyperclip
import time

def main():
    print("=" * 60)
    print("  Deploy: Fix Direct Messages RLS Policy")
    print("=" * 60)
    print()
    
    # Read SQL migration
    sql_file = os.path.join("supabase", "migrations", "20250114000001_fix_direct_messages_rls.sql")
    
    if not os.path.exists(sql_file):
        print(f"❌ Migration file not found: {sql_file}")
        return
    
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"✅ Found migration file")
    print()
    
    # Copy to clipboard
    try:
        pyperclip.copy(sql_content)
        print("✅ SQL copied to clipboard!")
    except:
        print("⚠️  Could not copy to clipboard")
    
    print()
    print("🌐 Opening Supabase SQL Editor...")
    print()
    
    # Open Supabase SQL Editor
    url = "https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql/new"
    webbrowser.open(url)
    
    time.sleep(2)
    
    print("=" * 60)
    print("📋 INSTRUCTIONS:")
    print("=" * 60)
    print()
    print("1. ✅ SQL Editor should be open in your browser")
    print("2. ✅ SQL is already in your clipboard")
    print("3. 📝 Paste (Ctrl+V) into the SQL editor")
    print("4. ▶️  Click 'Run' or press F5")
    print("5. ✅ Wait for success message")
    print()
    print("After SQL runs successfully:")
    print("- Press 'R' in Flutter terminal to restart app")
    print("- Test 'Nhắn tin' button → should open chat directly")
    print()
    print("=" * 60)
    print()

if __name__ == "__main__":
    main()
