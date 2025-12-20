import os
from supabase import create_client
from dotenv import load_dotenv
import json

load_dotenv()

sb = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

# Get sabo1 tournament
t = sb.table('tournaments').select('*').eq('title', 'sabo1').execute()

if not t.data:
    print("❌ Tournament 'sabo1' not found")
    exit(1)

tournament = t.data[0]
print("\n📋 TOURNAMENT DATA:")
print(f"  Title: {tournament['title']}")
print(f"  Prize Pool: {tournament.get('prize_pool')} VND")
print(f"  Prize Distribution (JSON): {json.dumps(tournament.get('prize_distribution'), indent=2)}")
print(f"  Custom Distribution: {json.dumps(tournament.get('custom_distribution'), indent=2)}")

# Get current standings
participants = sb.table('tournament_participants').select('user_id,users(full_name)').eq('tournament_id', tournament['id']).execute()
matches = sb.table('matches').select('player1_id,player2_id,winner_id,status').eq('tournament_id', tournament['id']).execute()

# Calculate wins
wins_count = {}
losses_count = {}
for match in matches.data:
    if match['status'] == 'completed' and match['winner_id']:
        winner = match['winner_id']
        p1 = match['player1_id']
        p2 = match['player2_id']
        loser = p1 if winner == p2 else p2
        wins_count[winner] = wins_count.get(winner, 0) + 1
        losses_count[loser] = losses_count.get(loser, 0) + 1

# Build rankings
rankings = []
for p in participants.data:
    user_id = p['user_id']
    name = p['users']['full_name'] if p.get('users') else 'Unknown'
    wins = wins_count.get(user_id, 0)
    losses = losses_count.get(user_id, 0)
    rankings.append({'name': name, 'wins': wins, 'losses': losses})

# Sort by wins
rankings.sort(key=lambda x: x['wins'], reverse=True)

print("\n🏆 CURRENT STANDINGS (by wins):")
for i, r in enumerate(rankings, 1):
    print(f"  {i}. {r['name']:20s} {r['wins']}/{r['losses']}")

# Calculate what prize money SHOULD be based on tournament settings
print("\n💰 PRIZE CALCULATION:")
prize_pool = tournament.get('prize_pool', 0)
prize_dist = tournament.get('prize_distribution')
custom_dist = tournament.get('custom_distribution')

if custom_dist:
    print("  Using CUSTOM DISTRIBUTION:")
    for i, item in enumerate(custom_dist, 1):
        amount = item.get('cashAmount', item.get('amount', 0))
        print(f"    Position {i}: {amount:,} VND")
elif prize_dist:
    print(f"  Using TEMPLATE: {prize_dist if isinstance(prize_dist, str) else prize_dist.get('template', 'unknown')}")
    print(f"  Prize Pool: {prize_pool:,} VND")
    
    # Calculate percentages based on template
    if isinstance(prize_dist, str):
        template = prize_dist
    elif isinstance(prize_dist, dict):
        template = prize_dist.get('template', 'standard')
    else:
        template = 'standard'
    
    # Default percentages for common templates
    percentages = {
        'standard': [50, 30, 20],
        'top_heavy': [60, 25, 15],
        'flat': [40, 30, 20, 10],
        'top_3': [60, 25, 15],
        'top_4': [40, 30, 15, 15],
    }
    
    if template in percentages:
        print(f"    Percentages: {percentages[template]}")
        for i, pct in enumerate(percentages[template], 1):
            amount = int(prize_pool * pct / 100)
            print(f"    Position {i}: {pct}% = {amount:,} VND")
    else:
        print(f"    ⚠️ Unknown template: {template}")
else:
    print("  ⚠️ No prize distribution found")
