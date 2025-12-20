import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
    exit(1)

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print('🔍 Checking tournaments table structure...\n')

try:
    # Get first tournament to see structure
    response = supabase.table('tournaments').select('*').limit(1).execute()
    
    if response.data:
        print('📋 Tournament columns:')
        for key in response.data[0].keys():
            print(f'  - {key}')
    else:
        print('⚠️  No tournaments found in database')
    
except Exception as e:
    print(f'❌ Error: {e}')
