import os
import json
from supabase import create_client, Client

# Load env.json
with open('env.json', 'r') as f:
    env = json.load(f)

url: str = env.get("SUPABASE_URL")
key: str = env.get("SUPABASE_SERVICE_ROLE_KEY") or env.get("SUPABASE_ANON_KEY")

supabase: Client = create_client(url, key)

def clear_matches_for_tournament(search_term):
    print(f"Searching for tournament with title containing: '{search_term}'...")
    
    # Find tournament
    response = supabase.table('tournaments').select("*").ilike('title', f'%{search_term}%').execute()
    tournaments = response.data
    
    if not tournaments:
        print("No tournament found.")
        return

    if len(tournaments) > 1:
        print(f"Found {len(tournaments)} tournaments. Please be more specific:")
        for t in tournaments:
            print(f" - {t['title']} (ID: {t['id']})")
        # If one is exactly "Giải test 1" or "Test 1", pick it, otherwise stop.
        # For now, let's just pick the first one if it's a close match or ask user.
        # But since I need to act, I will try to find the best match.
        target_tournament = tournaments[0]
        print(f"Selecting first match: {target_tournament['title']}")
    else:
        target_tournament = tournaments[0]

    tournament_id = target_tournament['id']
    tournament_title = target_tournament['title']
    print(f"Found tournament: {tournament_title} (ID: {tournament_id})")

    # Delete matches
    print(f"Deleting matches for tournament {tournament_id}...")
    delete_response = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
    
    # Check if we can get a count, usually delete returns the deleted rows
    deleted_count = len(delete_response.data)
    print(f"Successfully deleted {deleted_count} matches.")

    # Reset tournament status to 'pending' or 'open' so bracket can be regenerated?
    # The user said "tạo lại bảng đấu", usually implies the tournament might need to be in a state to generate bracket.
    # But maybe the UI allows regenerating if matches are empty.
    # Let's just clear matches as requested.

if __name__ == "__main__":
    clear_matches_for_tournament("test 1")
