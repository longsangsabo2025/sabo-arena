"""
Check all demo/test users in database before production cleanup
"""
import os
from supabase import create_client

# Load env
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://mogjjvscxjwvhtpkrlqr.supabase.co')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ')

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

print('🔍 CHECKING DEMO/TEST USERS IN DATABASE\n')
print('=' * 60)

# Query all users with test/demo patterns
patterns = ['test%', 'demo%', 'sabo%']
all_test_users = []

for pattern in patterns:
    result = supabase.table('users').select('*').ilike('username', pattern).execute()
    if result.data:
        all_test_users.extend(result.data)

# Remove duplicates
seen_ids = set()
unique_users = []
for user in all_test_users:
    if user['id'] not in seen_ids:
        seen_ids.add(user['id'])
        unique_users.append(user)

print(f'\n📊 FOUND {len(unique_users)} TEST/DEMO USERS:\n')

for i, user in enumerate(unique_users, 1):
    print(f'{i}. 👤 {user["username"]}')
    print(f'   ID: {user["id"]}')
    print(f'   Full Name: {user.get("full_name", "N/A")}')
    print(f'   Rank: {user.get("current_rank", "N/A")} (ELO: {user.get("current_elo", 1000)})')
    print(f'   Created: {user.get("created_at", "N/A")[:10]}')
    print()

print('=' * 60)
print(f'\n✅ SUMMARY:')
print(f'   Total test/demo users found: {len(unique_users)}')
print(f'\n⚠️  WARNING: Deleting these users will also delete ALL their related data!')
print(f'   This includes: tournaments, matches, challenges, posts, club memberships, etc.')
print(f'\n💡 Next step: Run clear_demo_users.py to delete them')
