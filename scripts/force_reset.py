"""
ELON MODE: FORCE RESET (No confirmation needed)
"""
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print('☢️  FORCE RESETTING test1...\n')

# Get tournament
tournament = supabase.table('tournaments').select('id, title, status').ilike('title', '%test1%').execute().data[0]
tid = tournament['id']

# Count
matches = supabase.table('matches').select('id', count='exact').eq('tournament_id', tid).execute()
participants = supabase.table('tournament_participants').select('id', count='exact').eq('tournament_id', tid).execute()

match_count = matches.count or 0
participant_count = participants.count or 0

print(f'🎯 Tournament: {tournament["title"]}')
print(f'💥 Deleting: {match_count} matches, {participant_count} participants\n')

# DELETE EVERYTHING
if match_count > 0:
    supabase.table('matches').delete().eq('tournament_id', tid).execute()
    print(f'✅ Deleted {match_count} matches')

if participant_count > 0:
    supabase.table('tournament_participants').delete().eq('tournament_id', tid).execute()
    print(f'✅ Deleted {participant_count} participants')

# Reset status
supabase.table('tournaments').update({
    'status': 'draft',
    'current_participants': 0
}).eq('id', tid).execute()
print(f'✅ Reset to DRAFT\n')

print(f'🎉 DONE! Tournament is CLEAN')
