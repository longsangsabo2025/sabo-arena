#!/usr/bin/env python3
"""
Deploy Club Members RLS Fix to Supabase
Opens Supabase SQL Editor and copies SQL to clipboard
"""

import os
import webbrowser
import pyperclip
import time

def main():
    print("=" * 60)
    print("  🔧 Deploy: Fix Club Members RLS Policy")
    print("=" * 60)
    print()
    
    # Read SQL file
    sql_file = os.path.join("sql", "fix_club_members_rls.sql")
    
    if not os.path.exists(sql_file):
        print(f"❌ SQL file not found: {sql_file}")
        return
    
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"✅ Found SQL file: {sql_file}")
    print(f"📄 SQL length: {len(sql_content)} characters")
    print()
    
    # Copy to clipboard
    try:
        pyperclip.copy(sql_content)
        print("✅ SQL copied to clipboard!")
    except Exception as e:
        print(f"⚠️  Could not copy to clipboard: {e}")
    
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
    print("1. Supabase SQL Editor should be opening in your browser")
    print("2. The SQL is already in your clipboard")
    print("3. Press Ctrl+V to paste the SQL")
    print("4. Click 'Run' button to execute")
    print("5. Verify the output shows 3 policies created")
    print()
    print("Expected policies:")
    print("  ✅ Anyone can view club members (SELECT)")
    print("  ✅ Users can join clubs (INSERT)")
    print("  ✅ Users can leave their clubs (DELETE)")
    print()
    print("=" * 60)
    print()
    
    # Show SQL preview
    print("📄 SQL PREVIEW:")
    print("=" * 60)
    lines = sql_content.split('\n')
    for i, line in enumerate(lines[:30], 1):  # Show first 30 lines
        print(f"{i:3d} | {line}")
    if len(lines) > 30:
        print(f"    | ... ({len(lines) - 30} more lines)")
    print("=" * 60)

if __name__ == '__main__':
    main()
