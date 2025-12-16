#!/usr/bin/env python3
"""
Tournament Analysis Tool - Analyze bracket generation and auto progression
"""

from supabase import create_client, Client

# Supabase configuration
url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
anon_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def analyze_tournament(tournament_name="sing1"):
    """Analyze tournament bracket and auto progression status"""
    supabase: Client = create_client(url, anon_key)
    
    print(f"🔍 Analyzing tournament '{tournament_name}'...")
    
    try:
        # Find tournament
        tournaments_response = supabase.table('tournaments').select('*').ilike('title', f'%{tournament_name}%').execute()
        if not tournaments_response.data:
            print(f"❌ No tournament found with '{tournament_name}'")
            return
            
        tournament = tournaments_response.data[0]
        tournament_id = tournament['id']
        print(f"✅ Found: {tournament['title']}")
        print(f"📋 Format: {tournament.get('bracket_format', 'unknown')}")
        
        # Get matches
        matches_response = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()
        matches = matches_response.data
        
        print(f"📊 Total matches: {len(matches)}")
        
        # Group by rounds and analyze
        rounds = {}
        for match in matches:
            round_num = match['round_number']
            if round_num not in rounds:
                rounds[round_num] = []
            rounds[round_num].append(match)
        
        print(f"\n📊 Round-by-Round Analysis:")
        for round_num in sorted(rounds.keys()):
            round_matches = rounds[round_num]
            assigned = sum(1 for m in round_matches if m['player1_id'] and m['player2_id'])
            completed = sum(1 for m in round_matches if m['winner_id'])
            
            status = "✅" if assigned == len(round_matches) else "❌" if assigned == 0 else "⚠️"
            print(f"  {status} Round {round_num}: {assigned}/{len(round_matches)} assigned, {completed} completed")
        
        # Auto progression check
        if len(rounds) > 1:
            print(f"\n🔍 Auto Progression Check:")
            
            r1_completed = sum(1 for m in rounds[1] if m['winner_id']) if 1 in rounds else 0
            r2_assigned = sum(1 for m in rounds[2] if m['player1_id'] and m['player2_id']) if 2 in rounds else 0
            
            if r1_completed >= 2 and r2_assigned == 0:
                print("❌ AUTO PROGRESSION NOT WORKING")
                print("💡 Round 1 has winners but Round 2 empty")
            elif r1_completed >= 2 and r2_assigned > 0:
                print("✅ AUTO PROGRESSION WORKING")
            else:
                print("ℹ️ Need Round 1 completions to test auto progression")
                
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    import sys
    tournament_name = sys.argv[1] if len(sys.argv) > 1 else "sing1"
    analyze_tournament(tournament_name)