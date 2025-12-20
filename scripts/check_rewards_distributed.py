import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from supabase import create_client, Client

url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
supabase: Client = create_client(url, key)

# Check tournament status
tournament = supabase.table('tournaments').select('*').eq('title', 'test1').single().execute()
print(f"\n=== TOURNAMENT STATUS ===")
print(f"Title: {tournament.data['title']}")
print(f"Status: {tournament.data['status']}")
print(f"Completed at: {tournament.data.get('completed_at', 'Not completed')}")

# Check tournament_results
results = supabase.table('tournament_results').select('*').eq('tournament_id', tournament.data['id']).order('position').execute()
print(f"\n=== TOURNAMENT_RESULTS ({len(results.data)} records) ===")
for r in results.data:
    print(f"Position {r['position']}: {r['participant_name']} | ELO: {r['elo_change']} | SPA: {r['spa_reward']} | Money: {r.get('prize_money_vnd', 0)}")

# Check users' current balances (if tournament_results exists)
if len(results.data) > 0:
    participant_ids = [r['participant_id'] for r in results.data]
    users = supabase.table('users').select('id, username, full_name, elo_rating').in_('id', participant_ids).execute()

    print(f"\n=== USERS CURRENT ELO ===")
    for user in users.data:
        print(f"{user.get('full_name', user.get('username', 'Unknown'))}: ELO={user['elo_rating']}")
else:
    print(f"\n⚠️ NO TOURNAMENT_RESULTS FOUND - REWARDS NOT EXECUTED YET!")

# Check if rewards were executed
print(f"\n=== REWARD EXECUTION STATUS ===")
print(f"rewards_executed field: {tournament.data.get('rewards_executed', 'NOT FOUND')}")
print(f"rewards_executed_at: {tournament.data.get('rewards_executed_at', 'NOT FOUND')}")
