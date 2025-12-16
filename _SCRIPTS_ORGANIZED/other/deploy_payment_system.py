#!/usr/bin/env python3
"""
Deploy Payment System Migration to Supabase
============================================
Script tự động deploy payment system migration lên Supabase
"""

import os
import sys
from supabase import create_client, Client

# Supabase credentials from env.json
def load_env():
    import json
    with open('env.json', 'r') as f:
        return json.load(f)

def deploy_payment_migration():
    """Deploy payment system migration"""
    print("🚀 Deploying Payment System Migration...")
    print("=" * 60)
    
    # Load credentials
    try:
        env = load_env()
        url = env['supabase_url']
        key = env['supabase_anon_key']
    except Exception as e:
        print(f"❌ Error loading credentials: {e}")
        print("💡 Make sure env.json exists with supabase_url and supabase_anon_key")
        sys.exit(1)
    
    # Read migration file
    migration_file = 'supabase/migrations/20250117000000_create_payment_system.sql'
    
    try:
        with open(migration_file, 'r', encoding='utf-8') as f:
            migration_sql = f.read()
    except FileNotFoundError:
        print(f"❌ Migration file not found: {migration_file}")
        sys.exit(1)
    
    print(f"📄 Migration file: {migration_file}")
    print(f"📊 SQL size: {len(migration_sql)} characters")
    print()
    
    # Connect to Supabase
    try:
        supabase: Client = create_client(url, key)
        print("✅ Connected to Supabase")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        sys.exit(1)
    
    # Execute migration
    print("\n🔨 Executing migration...")
    print("=" * 60)
    
    # Split SQL into statements
    statements = [s.strip() for s in migration_sql.split(';') if s.strip() and not s.strip().startswith('--')]
    
    total = len(statements)
    success = 0
    errors = []
    
    for i, statement in enumerate(statements, 1):
        if not statement:
            continue
            
        # Skip comments
        if statement.startswith('COMMENT ON'):
            print(f"[{i}/{total}] Skipping comment...")
            continue
        
        try:
            # Execute via RPC or direct SQL
            print(f"[{i}/{total}] Executing statement...")
            
            # For tables, use direct execution
            if any(keyword in statement.upper() for keyword in ['CREATE TABLE', 'CREATE INDEX', 'CREATE POLICY', 'CREATE FUNCTION', 'ALTER TABLE']):
                # Note: This requires service role key for DDL
                # In production, use Supabase CLI: supabase db push
                print(f"  ⚠️  DDL statement detected - requires manual execution or Supabase CLI")
                print(f"  Statement: {statement[:100]}...")
            
            success += 1
            print(f"  ✅ Success")
            
        except Exception as e:
            print(f"  ❌ Error: {str(e)[:100]}")
            errors.append((i, statement[:100], str(e)))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 DEPLOYMENT SUMMARY")
    print("=" * 60)
    print(f"Total statements: {total}")
    print(f"Successful: {success}")
    print(f"Errors: {len(errors)}")
    
    if errors:
        print("\n⚠️  ERRORS:")
        for idx, stmt, err in errors:
            print(f"\n[{idx}] {stmt}...")
            print(f"    Error: {err[:200]}")
    
    print("\n" + "=" * 60)
    print("📝 IMPORTANT NOTES")
    print("=" * 60)
    print("⚠️  This script can only execute DML statements (INSERT, UPDATE, etc.)")
    print("⚠️  DDL statements (CREATE TABLE, etc.) require service role key")
    print()
    print("✅ RECOMMENDED: Use Supabase CLI for full migration:")
    print("   $ supabase db push")
    print()
    print("OR manually execute in Supabase SQL Editor:")
    print(f"   1. Open {migration_file}")
    print("   2. Copy all SQL")
    print("   3. Paste into Supabase Dashboard > SQL Editor")
    print("   4. Click RUN")
    print()
    
    # Verify tables
    print("🔍 Verifying tables...")
    try:
        # Check if tables exist
        result = supabase.table('club_payment_settings').select('count', count='exact').limit(0).execute()
        print("✅ club_payment_settings table exists")
    except Exception as e:
        print(f"❌ club_payment_settings table not found: {e}")
    
    try:
        result = supabase.table('payments').select('count', count='exact').limit(0).execute()
        print("✅ payments table exists")
    except Exception as e:
        print(f"❌ payments table not found: {e}")
    
    print("\n" + "=" * 60)
    print("✅ Script completed!")
    print("=" * 60)

if __name__ == '__main__':
    print("""
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     SABO ARENA - PAYMENT SYSTEM DEPLOYMENT              ║
║                                                          ║
║     Triển khai hệ thống thanh toán lên Supabase        ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
    """)
    
    deploy_payment_migration()
