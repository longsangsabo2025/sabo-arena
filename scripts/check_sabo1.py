import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

# Get tournament details
t = sb.table('tournaments').select('*').eq('title', 'sabo1').execute()

if not t.data:
    print("❌ Tournament 'sabo1' not found")
    exit(1)

tournament = t.data[0]
print("\n📋 TOURNAMENT INFO:")
print(f"  ID: {tournament['id']}")
print(f"  Title: {tournament['title']}")
print(f"  Prize Pool: {tournament.get('prize_pool', 0):,} VND")
print(f"  Prize Distribution: {tournament.get('prize_distribution')}")
print(f"  Custom Distribution: {tournament.get('custom_distribution')}")
print(f"  Status: {tournament['status']}")

# Get participants and calculate rankings
participants = sb.table('tournament_participants').select('user_id,users(full_name)').eq('tournament_id', tournament['id']).execute()
matches = sb.table('matches').select('player1_id,player2_id,winner_id,status').eq('tournament_id', tournament['id']).execute()

# Calculate wins for each player
wins_count = {}
losses_count = {}
for match in matches.data:
    if match['status'] == 'completed' and match['winner_id']:
        winner = match['winner_id']
        loser = match['player1_id'] if match['winner_id'] == match['player2_id'] else match['player2_id']
        wins_count[winner] = wins_count.get(winner, 0) + 1
        losses_count[loser] = losses_count.get(loser, 0) + 1

# Build rankings
rankings = []
for p in participants.data:
    user_id = p['user_id']
    name = p['users']['full_name'] if p.get('users') else 'Unknown'
    wins = wins_count.get(user_id, 0)
    losses = losses_count.get(user_id, 0)
    rankings.append({
        'name': name,
        'wins': wins,
        'losses': losses,
        'user_id': user_id
    })

# Sort by wins
rankings.sort(key=lambda x: x['wins'], reverse=True)

print("\n🏆 CURRENT RANKINGS:")
prize_pool = tournament.get('prize_pool', 0)
custom_dist = tournament.get('custom_distribution')

for i, r in enumerate(rankings, 1):
    # Calculate prize money based on custom distribution or default
    prize = 0
    if custom_dist and isinstance(custom_dist, list) and i <= len(custom_dist):
        prize_item = custom_dist[i-1]
        prize = prize_item.get('cashAmount', prize_item.get('amount', 0))
    elif prize_pool > 0:
        # Default percentages for top positions
        percentages = {1: 50, 2: 30, 3: 20}
        if i in percentages:
            prize = int(prize_pool * percentages[i] / 100)
    
    print(f"  {i}. {r['name']:20s} {r['wins']}/{r['losses']} - {prize:,} VND")
