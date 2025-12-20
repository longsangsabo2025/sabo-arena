import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from supabase import create_client, Client

url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
supabase: Client = create_client(url, key)

print("=" * 80)
print("🏆 CHECKING CURRENT RANKINGS FOR TOURNAMENT TEST1")
print("=" * 80)

# Get tournament
tournament = supabase.table('tournaments').select('id, title, status, tournament_type').eq('title', 'test1').single().execute()
print(f"\n📋 Tournament: {tournament.data['title']}")
print(f"   Status: {tournament.data['status']}")
print(f"   Type: {tournament.data['tournament_type']}")
print(f"   ID: {tournament.data['id']}")

tournament_id = tournament.data['id']

# Get participants
participants = supabase.table('tournament_participants').select('user_id, users(username, full_name)').eq('tournament_id', tournament_id).execute()
print(f"\n👥 Participants: {len(participants.data)}")
participant_map = {p['user_id']: p['users']['full_name'] or p['users']['username'] for p in participants.data}

# Get all matches
matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number', ascending=False).execute()
print(f"\n🎮 Total Matches: {len(matches.data)}")

# Analyze matches by round
rounds = {}
for match in matches.data:
    round_name = match['round_name']
    if round_name not in rounds:
        rounds[round_name] = []
    rounds[round_name].append(match)

print("\n📊 MATCHES BY ROUND:")
print("-" * 80)
for round_name in sorted(rounds.keys(), key=lambda x: -len(rounds[x])):
    print(f"\n{round_name.upper()} ({len(rounds[round_name])} matches):")
    for match in rounds[round_name]:
        p1_name = participant_map.get(match['player1_id'], 'Unknown')
        p2_name = participant_map.get(match['player2_id'], 'Unknown')
        winner_name = participant_map.get(match['winner_id'], 'TBD') if match['winner_id'] else 'TBD'
        loser_name = participant_map.get(match['loser_id'], 'Unknown') if match['loser_id'] else 'TBD'
        status = match['status']
        
        print(f"  • {p1_name} vs {p2_name}")
        print(f"    Score: {match['player1_score']}-{match['player2_score']} | Status: {status}")
        if match['winner_id']:
            print(f"    ✅ Winner: {winner_name} | ❌ Loser: {loser_name}")

# Calculate W/L records
records = {}
for participant_id in participant_map.keys():
    wins = 0
    losses = 0
    for match in matches.data:
        if match['status'] == 'completed':
            if match['winner_id'] == participant_id:
                wins += 1
            elif match['loser_id'] == participant_id:
                losses += 1
    records[participant_id] = {'wins': wins, 'losses': losses, 'name': participant_map[participant_id]}

# Determine bracket positions
print("\n" + "=" * 80)
print("🏅 BRACKET POSITION ANALYSIS")
print("=" * 80)

bracket_positions = {}

# Find Finals match
finals_matches = [m for m in matches.data if 'final' in m['round_name'].lower() and 'semi' not in m['round_name'].lower()]
if finals_matches:
    finals = finals_matches[0]
    if finals['winner_id']:
        bracket_positions[finals['winner_id']] = {'rank': 1, 'round': 'Finals Winner'}
        bracket_positions[finals['loser_id']] = {'rank': 2, 'round': 'Finals Loser'}
        print(f"\n🥇 Rank 1 (Finals Winner): {participant_map[finals['winner_id']]}")
        print(f"🥈 Rank 2 (Finals Loser): {participant_map[finals['loser_id']]}")

# Find Semi-finals losers
semi_matches = [m for m in matches.data if 'semi' in m['round_name'].lower()]
if semi_matches:
    print(f"\n🥉 Rank 3 (Semi-finals Losers - tied):")
    semi_losers = []
    for match in semi_matches:
        if match['loser_id'] and match['loser_id'] not in bracket_positions:
            bracket_positions[match['loser_id']] = {'rank': 3, 'round': 'Semi-finals Loser'}
            semi_losers.append(participant_map[match['loser_id']])
            print(f"   • {participant_map[match['loser_id']]}")

# Find Quarter-finals losers
quarter_matches = [m for m in matches.data if 'quarter' in m['round_name'].lower()]
if quarter_matches:
    print(f"\n🎯 Rank 5 (Quarter-finals Losers - tied):")
    quarter_losers = []
    for match in quarter_matches:
        if match['loser_id'] and match['loser_id'] not in bracket_positions:
            bracket_positions[match['loser_id']] = {'rank': 5, 'round': 'Quarter-finals Loser'}
            quarter_losers.append(participant_map[match['loser_id']])
            print(f"   • {participant_map[match['loser_id']]}")

# Summary with W/L records
print("\n" + "=" * 80)
print("📈 FINAL RANKINGS SUMMARY (with W/L records)")
print("=" * 80)

# Sort by bracket position
ranked_players = sorted(bracket_positions.items(), key=lambda x: (x[1]['rank'], -records[x[0]]['wins']))

position = 1
for player_id, bracket_info in ranked_players:
    player_name = participant_map[player_id]
    w = records[player_id]['wins']
    l = records[player_id]['losses']
    rank = bracket_info['rank']
    round_info = bracket_info['round']
    
    if position <= 4:
        icon = ['🥇', '🥈', '🥉', '🥉'][position - 1]
    else:
        icon = f"{position}."
    
    print(f"{icon} Position {position} (Rank {rank}): {player_name} | W/L: {w}/{l} | {round_info}")
    position += 1

# Check if tournament_results exists
results = supabase.table('tournament_results').select('*').eq('tournament_id', tournament_id).execute()
if results.data:
    print("\n" + "=" * 80)
    print("💰 TOURNAMENT_RESULTS (Rewards Distributed)")
    print("=" * 80)
    for result in sorted(results.data, key=lambda x: x['position']):
        print(f"Position {result['position']}: {result['participant_name']}")
        print(f"  ELO: {result['elo_change']:+d} | SPA: {result['spa_reward']} | Money: {result.get('prize_money_vnd', 0):,} VND")
else:
    print("\n⚠️  No tournament_results found - rewards not yet distributed")

print("\n" + "=" * 80)
