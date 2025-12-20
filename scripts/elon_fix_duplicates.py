"""
ELON FIX: Delete the broken advancement matches
These are matches where a player faces themselves - IMPOSSIBLE
"""
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print('🚀 ELON MODE: FIXING DUPLICATE MATCHES\n')

# Get tournament
tournament = supabase.table('tournaments').select('id, title').ilike('title', '%test1%').execute().data[0]
tid = tournament['id']

# Find ALL matches where player1_id == player2_id
matches = supabase.table('matches').select('*').eq('tournament_id', tid).execute().data

duplicates = [m for m in matches if m['player1_id'] and m['player2_id'] and m['player1_id'] == m['player2_id']]

if not duplicates:
    print('✅ No duplicate matches found')
    exit(0)

print(f'💥 FOUND {len(duplicates)} BROKEN MATCHES:')
for d in duplicates:
    print(f'  Match {d["match_number"]} (Round {d["round_number"]}): {d["player1_id"][:8]} vs themselves')

print(f'\n🔧 FIXING: Delete these impossible matches')
confirmation = input(f'Type "FIX IT" to delete {len(duplicates)} broken matches: ').strip()

if confirmation != 'FIX IT':
    print('❌ Cancelled')
    exit(0)

# Delete the broken matches
for d in duplicates:
    supabase.table('matches').delete().eq('id', d['id']).execute()
    print(f'  ✅ Deleted match {d["match_number"]}')

print(f'\n🎉 FIXED! Deleted {len(duplicates)} impossible matches')
print(f'✅ Bracket is now VALID')
