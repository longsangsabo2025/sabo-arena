#!/usr/bin/env python3
import os
from supabase import create_client, Client

# Supabase configuration
url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def clear_tournament(tournament_name):
    """Clear tournament and all related data"""
    try:
        supabase: Client = create_client(url, key)
        
        # Find tournament by title
        tournaments = supabase.table('tournaments').select('*').eq('title', tournament_name).execute()
        
        if not tournaments.data:
            print(f"❌ Tournament '{tournament_name}' not found")
            return False
            
        tournament = tournaments.data[0]
        tournament_id = tournament['id']
        
        print(f"🎯 Found tournament: {tournament['title']} (ID: {tournament_id})")
        
        # Delete matches first (foreign key constraint)
        matches_result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
        print(f"🗑️ Deleted {len(matches_result.data) if matches_result.data else 0} matches")
        
        # Delete tournament participants
        participants_result = supabase.table('tournament_participants').delete().eq('tournament_id', tournament_id).execute()
        print(f"🗑️ Deleted {len(participants_result.data) if participants_result.data else 0} participants")
        
        # Delete tournament
        tournament_result = supabase.table('tournaments').delete().eq('id', tournament_id).execute()
        print(f"🗑️ Deleted tournament")
        
        print(f"✅ Successfully cleared tournament '{tournament_name}'")
        return True
        
    except Exception as e:
        print(f"❌ Error clearing tournament: {e}")
        return False

if __name__ == "__main__":
    import sys
    tournament_name = sys.argv[1] if len(sys.argv) > 1 else "sing1"
    clear_tournament(tournament_name)