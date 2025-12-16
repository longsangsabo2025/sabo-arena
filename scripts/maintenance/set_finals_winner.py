"""
Set winner and proper scores for Finals match
"""
import os
import sys
import random

try:
    from supabase import create_client, Client
except ImportError:
    print("Installing supabase...")
    os.system("pip install supabase")
    from supabase import create_client, Client

def main():
    # Initialize Supabase client
    url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
    
    supabase: Client = create_client(url, key)
    
    print("🏆 Setting Finals match winner and scores...")
    
    # Find sabo1 tournament
    tournament_result = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()
    tournament = tournament_result.data[0]
    tournament_id = tournament['id']
    
    # Get Finals match (Round 4, Match 15)
    finals_result = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 4).eq('match_number', 15).execute()
    
    if not finals_result.data:
        print("❌ Finals match not found")
        return
    
    finals_match = finals_result.data[0]
    match_id = finals_match['id']
    player1_id = finals_match['player1_id'] 
    player2_id = finals_match['player2_id']
    
    if not player1_id or not player2_id:
        print("❌ Finals match missing players")
        return
    
    # Get player names
    try:
        p1_result = supabase.table('user_profiles').select('username').eq('id', player1_id).execute()
        p2_result = supabase.table('user_profiles').select('username').eq('id', player2_id).execute()
        
        p1_name = p1_result.data[0]['username'] if p1_result.data else f"Player({player1_id[:8]})"
        p2_name = p2_result.data[0]['username'] if p2_result.data else f"Player({player2_id[:8]})"
    except:
        p1_name = f"Player({player1_id[:8]})"
        p2_name = f"Player({player2_id[:8]})"
    
    print(f"🏆 Finals: {p1_name} vs {p2_name}")
    
    # Randomly choose winner and set realistic scores
    winner_id = random.choice([player1_id, player2_id])
    winner_name = p1_name if winner_id == player1_id else p2_name
    
    # Set realistic final match scores (closer game)
    if winner_id == player1_id:
        p1_score = 3
        p2_score = 2  # Closer final game
    else:
        p1_score = 2
        p2_score = 3
    
    print(f"🎯 Setting winner: {winner_name}")
    print(f"📊 Final Score: {p1_name} {p1_score} - {p2_score} {p2_name}")
    
    try:
        # Update Finals match with winner and scores
        update_result = supabase.table('matches').update({
            'winner_id': winner_id,
            'player1_score': p1_score,
            'player2_score': p2_score,
            'status': 'completed'
        }).eq('id', match_id).execute()
        
        print("✅ Finals match updated successfully!")
        
        # Also update tournament status to completed
        tournament_update = supabase.table('tournaments').update({
            'status': 'completed'
        }).eq('id', tournament_id).execute()
        
        print("🏆 Tournament marked as completed!")
        print(f"🎉 CHAMPION: {winner_name}!")
        
    except Exception as e:
        print(f"❌ Error updating Finals: {e}")

if __name__ == "__main__":
    main()