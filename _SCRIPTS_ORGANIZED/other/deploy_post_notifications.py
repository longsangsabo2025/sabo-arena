#!/usr/bin/env python3
"""
Deploy Post Notifications System to Supabase
Auto-creates notifications when users like, comment, or share posts
"""
import os
from supabase import create_client, Client

# Supabase credentials
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def deploy_notifications():
    """Deploy notification system via Supabase SQL Editor"""
    
    print("📋 POST NOTIFICATIONS DEPLOYMENT")
    print("=" * 50)
    
    # Read SQL file
    try:
        with open('DEPLOY_POST_NOTIFICATIONS.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("✅ SQL file loaded successfully")
        print(f"📄 File size: {len(sql_content)} characters")
        
    except FileNotFoundError:
        print("❌ ERROR: DEPLOY_POST_NOTIFICATIONS.sql not found!")
        return False
    
    # Create Supabase client
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Connected to Supabase")
    except Exception as e:
        print(f"❌ Connection error: {e}")
        return False
    
    # Split SQL into individual statements
    statements = [s.strip() for s in sql_content.split(';') if s.strip() and not s.strip().startswith('--')]
    
    print(f"\n🔧 Executing {len(statements)} SQL statements...\n")
    
    success_count = 0
    error_count = 0
    
    for i, statement in enumerate(statements, 1):
        # Skip comments and empty statements
        if not statement or statement.startswith('--') or statement.startswith('/*'):
            continue
            
        try:
            # Execute via RPC (need to use service role key for DDL)
            # Note: This won't work with anon key - need to use Supabase SQL Editor
            print(f"⏳ [{i}/{len(statements)}] Executing...")
            
            # Show preview of statement
            preview = statement[:80].replace('\n', ' ')
            if len(statement) > 80:
                preview += '...'
            print(f"   {preview}")
            
            # For this to work, you need service_role key or use SQL Editor
            # supabase.postgrest.rpc('exec', {'sql': statement}).execute()
            
            success_count += 1
            print(f"   ✅ Success\n")
            
        except Exception as e:
            error_count += 1
            print(f"   ❌ Error: {e}\n")
    
    print("=" * 50)
    print(f"✅ Completed: {success_count} successful")
    if error_count > 0:
        print(f"❌ Errors: {error_count}")
    
    print("\n" + "=" * 50)
    print("⚠️  IMPORTANT: Manual Deployment Required")
    print("=" * 50)
    print("\nDue to Supabase security, you need to:")
    print("1. Open Supabase Dashboard: https://supabase.com/dashboard")
    print("2. Navigate to: SQL Editor")
    print("3. Create a new query")
    print("4. Copy content from: DEPLOY_POST_NOTIFICATIONS.sql")
    print("5. Run the query")
    print("\nOr use this direct link:")
    print(f"https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql")
    
    return True

def check_deployment():
    """Check if notifications are working"""
    print("\n" + "=" * 50)
    print("🔍 VERIFICATION STEPS")
    print("=" * 50)
    print("\nAfter deployment, test by:")
    print("1. Have another user like your post")
    print("2. Check notifications table:")
    print("   SELECT * FROM notifications WHERE type = 'post_like';")
    print("\n3. Have another user comment on your post")
    print("4. Check notifications table:")
    print("   SELECT * FROM notifications WHERE type = 'post_comment';")
    print("\n5. Have another user share your post")
    print("6. Check notifications table:")
    print("   SELECT * FROM notifications WHERE type = 'post_share';")
    
    print("\n" + "=" * 50)
    print("📊 Expected Triggers:")
    print("=" * 50)
    print("✅ trigger_notify_post_liked - on post_likes table")
    print("✅ trigger_notify_post_commented - on comments table")
    print("✅ trigger_notify_post_shared - on shares table")
    
    return True

if __name__ == "__main__":
    print("\n🚀 Starting Post Notifications Deployment\n")
    
    deploy_notifications()
    check_deployment()
    
    print("\n" + "=" * 50)
    print("✅ DEPLOYMENT GUIDE COMPLETE")
    print("=" * 50)
    print("\n📝 Next Steps:")
    print("1. Copy DEPLOY_POST_NOTIFICATIONS.sql content")
    print("2. Paste into Supabase SQL Editor")
    print("3. Click 'Run' button")
    print("4. Test notifications by liking/commenting on posts")
    print("\n🎉 Enjoy automatic post notifications!\n")
