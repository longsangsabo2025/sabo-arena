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

print('🔍 Checking test1 tournament matches...\n')

try:
    # Find tournament test1
    response = supabase.table('tournaments').select('id, title').ilike('title', '%test1%').execute()
    
    if not response.data:
        print('❌ Tournament "test1" not found!')
        exit(1)
    
    tournament = response.data[0]
    tournament_id = tournament['id']
    print(f'✅ Tournament: {tournament["title"]} (ID: {tournament_id})\n')
    
    # Get all matches with player info
    matches_response = supabase.table('matches').select('''
        id,
        round_number,
        match_number,
        player1_id,
        player2_id,
        status
    ''').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()
    
    matches = matches_response.data
    print(f'📊 Total matches: {len(matches)}\n')
    
    if len(matches) == 0:
        print('✅ No matches in this tournament')
        exit(0)
    
    # Group by rounds
    rounds = {}
    duplicates = []
    
    for match in matches:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        
        rounds[round_num].append(match)
        
        # Check for duplicates (same player as both player1 and player2)
        if match['player1_id'] and match['player2_id']:
            if match['player1_id'] == match['player2_id']:
                duplicates.append(match)
    
    # Display matches by round
    for round_num in sorted(rounds.keys()):
        round_matches = rounds[round_num]
        print(f'📌 Round {round_num}: {len(round_matches)} matches')
        
        for match in round_matches:
            p1 = match['player1_id'][:8] if match['player1_id'] else 'TBD'
            p2 = match['player2_id'][:8] if match['player2_id'] else 'TBD'
            print(f'  M{match["match_number"]}: {p1} vs {p2} ({match["status"]})')
    
    # Report duplicates
    if duplicates:
        print(f'\n⚠️  WARNING: Found {len(duplicates)} matches with duplicate players!')
        for dup in duplicates:
            print(f'  - Match {dup["match_number"]} (Round {dup["round_number"]}): Player {dup["player1_id"][:8]} vs themselves')
    else:
        print('\n✅ No duplicate player matches found')
    
except Exception as e:
    print(f'❌ Error: {e}')
    exit(1)
