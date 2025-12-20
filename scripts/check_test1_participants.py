import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print('🔍 Checking test1 tournament participants...\n')

try:
    # Find tournament
    tournament = supabase.table('tournaments').select('id, title').ilike('title', '%test1%').execute().data[0]
    tid = tournament['id']
    print(f'✅ Tournament: {tournament["title"]} ({tid})\n')
    
    # Get participants
    parts = supabase.table('tournament_participants').select('*').eq('tournament_id', tid).execute().data
    
    print(f'📊 Total participants: {len(parts)}\n')
    
    if parts:
        print('Participants:')
        for p in parts:
            print(f'  - {p.get("user_id", "NO USER_ID")} | Payment: {p.get("payment_status", "?")}')
    
    # Get matches
    matches = supabase.table('matches').select('player1_id, player2_id').eq('tournament_id', tid).limit(5).execute().data
    
    if matches:
        print(f'\n📌 Sample matches (first 5):')
        for m in matches:
            p1 = m['player1_id'][:8] if m['player1_id'] else 'None'
            p2 = m['player2_id'][:8] if m['player2_id'] else 'None'
            same = '❌ SAME!' if (m['player1_id'] and m['player2_id'] and m['player1_id'] == m['player2_id']) else '✅'
            print(f'  {p1} vs {p2} {same}')
    
except Exception as e:
    print(f'❌ Error: {e}')
