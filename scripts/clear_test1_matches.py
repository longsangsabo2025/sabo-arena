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

print('🧹 Clear matches for tournament "test1"...\n')

try:
    # 1. Find tournament "test1"
    print('🔍 Looking for tournament "test1"...')
    response = supabase.table('tournaments').select('id, title, status').ilike('title', '%test1%').execute()
    
    if not response.data:
        print('❌ Tournament "test1" not found!')
        exit(1)
    
    tournament = response.data[0]
    tournament_id = tournament['id']
    tournament_name = tournament['title']
    print(f'✅ Found tournament: {tournament_name} (ID: {tournament_id})')
    
    # 2. Count matches
    print('\n🔢 Counting matches...')
    count_response = supabase.table('matches').select('id', count='exact').eq('tournament_id', tournament_id).execute()
    match_count = count_response.count
    
    if match_count == 0:
        print('✅ No matches found for this tournament!')
        exit(0)
    
    print(f'📊 Found {match_count} matches')
    
    # 3. Confirm deletion
    print(f'\n⚠️  WARNING: This will delete {match_count} matches!')
    confirmation = input('Type "DELETE" to confirm: ').strip()
    
    if confirmation != 'DELETE':
        print('❌ Operation cancelled')
        exit(0)
    
    # 4. Delete matches
    print('\n🗑️  Deleting matches...')
    supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
    
    print(f'✅ Successfully deleted {match_count} matches from tournament "{tournament_name}"!')
    
except Exception as e:
    print(f'❌ Error: {e}')
    exit(1)
