"""
ELON MODE: Test bracket generation to find duplicate bug
First principles: A player CANNOT play against themselves
"""
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print('🔬 ELON MODE: Testing bracket logic\n')

# Get test1 tournament
tournament = supabase.table('tournaments').select('id, title').ilike('title', '%test1%').execute().data[0]
tid = tournament['id']

# Get ALL matches
matches = supabase.table('matches').select('id, player1_id, player2_id, round_number, match_number').eq('tournament_id', tid).order('round_number').order('match_number').execute().data

print(f'📊 Tournament: {tournament["title"]}')
print(f'📊 Total matches: {len(matches)}\n')

# Physics check: Find violations
violations = []
for m in matches:
    p1 = m['player1_id']
    p2 = m['player2_id']
    
    # VIOLATION: Same player
    if p1 and p2 and p1 == p2:
        violations.append({
            'match_id': m['id'],
            'round': m['round_number'],
            'match_num': m['match_number'],
            'player': p1,
            'type': 'DUPLICATE_PLAYER'
        })

if violations:
    print(f'❌ FOUND {len(violations)} VIOLATIONS!\n')
    for v in violations:
        print(f'  Round {v["round"]}, Match {v["match_num"]}: Player {v["player"][:8]} vs THEMSELVES')
        print(f'    Match ID: {v["match_id"]}')
    
    print(f'\n💥 ROOT CAUSE: Bracket generation is BROKEN')
    print(f'🔧 FIX: Need to regenerate bracket with correct logic')
    
else:
    print('✅ No violations found - bracket is VALID')

print(f'\n🚀 NEXT STEPS:')
print(f'  1. Delete ALL matches for test1')
print(f'  2. Regenerate bracket with CORRECT logic')
print(f'  3. Add validation to PREVENT this bug from happening again')
