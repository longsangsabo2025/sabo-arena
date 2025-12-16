import os
import requests
from dotenv import load_dotenv

# Load credentials
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

print('🗑️  DELETING ALL USERS...\n')
print(f'Connected: {SUPABASE_URL}\n')

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

# Method 1: Delete from public.users using exec_sql
print('1. Deleting from public.users...')
try:
    response = requests.post(
        f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
        headers=headers,
        json={'query': 'DELETE FROM public.users;'}
    )
    if response.status_code == 200:
        print('   ✅ Deleted from public.users\n')
    else:
        print(f'   ❌ Failed: {response.status_code} - {response.text}\n')
except Exception as e:
    print(f'   ❌ Error: {e}\n')

# Method 2: Delete from auth.users using exec_sql
print('2. Deleting from auth.users...')
try:
    response = requests.post(
        f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
        headers=headers,
        json={'query': 'DELETE FROM auth.users;'}
    )
    if response.status_code == 200:
        print('   ✅ Deleted from auth.users\n')
    else:
        print(f'   ❌ Failed: {response.status_code} - {response.text}\n')
except Exception as e:
    print(f'   ❌ Error: {e}\n')

# Verify
print('📊 Verifying...')
try:
    response = requests.get(
        f'{SUPABASE_URL}/rest/v1/users?select=id',
        headers=headers
    )
    if response.status_code == 200:
        users = response.json()
        print(f'   Remaining users: {len(users)}')
        
        if len(users) == 0:
            print('\n🎉 All users deleted successfully!')
        else:
            print(f'\n⚠️  {len(users)} users still remain!')
    else:
        print(f'   ❌ Failed to verify: {response.status_code}')
except Exception as e:
    print(f'   ❌ Error: {e}')
