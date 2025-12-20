"""
ELON MODE: COMPLETE TOURNAMENT RESET
Delete ALL data for test1 tournament to start fresh
"""
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print('☢️  ELON MODE: COMPLETE TOURNAMENT RESET\n')

# Get tournament
tournament = supabase.table('tournaments').select('id, title, status').ilike('title', '%test1%').execute().data[0]
tid = tournament['id']
print(f'🎯 Target: {tournament["title"]} (ID: {tid})')
print(f'📊 Current status: {tournament["status"]}\n')

# Count what we're deleting
matches = supabase.table('matches').select('id', count='exact').eq('tournament_id', tid).execute()
participants = supabase.table('tournament_participants').select('id', count='exact').eq('tournament_id', tid).execute()

match_count = matches.count or 0
participant_count = participants.count or 0

print(f'💥 ABOUT TO DELETE:')
print(f'  - {match_count} matches')
print(f'  - {participant_count} participants')
print(f'  - Reset tournament status to "draft"\n')

confirmation = input('Type "RESET" to proceed: ').strip()

if confirmation != 'RESET':
    print('❌ Cancelled')
    exit(0)

print('\n🗑️  Deleting...')

# 1. Delete all matches
if match_count > 0:
    supabase.table('matches').delete().eq('tournament_id', tid).execute()
    print(f'  ✅ Deleted {match_count} matches')

# 2. Delete all participants
if participant_count > 0:
    supabase.table('tournament_participants').delete().eq('tournament_id', tid).execute()
    print(f'  ✅ Deleted {participant_count} participants')

# 3. Reset tournament status
supabase.table('tournaments').update({
    'status': 'draft',
    'current_participants': 0
}).eq('id', tid).execute()
print(f'  ✅ Reset tournament to DRAFT status')

print(f'\n🎉 COMPLETE! Tournament test1 is now CLEAN')
print(f'✅ Ready for fresh tournament creation test')
