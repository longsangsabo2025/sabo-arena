#!/usr/bin/env python3
"""Clear matches only for tournament"""

import os
from supabase import create_client, Client

# Supabase configuration
url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def clear_matches_only(tournament_name):
    """Clear matches only and reset tournament status"""
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
        
        # Delete matches only
        matches_result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
        print(f"🗑️ Deleted {len(matches_result.data) if matches_result.data else 0} matches")
        
        # Reset tournament status to registration
        update_data = {
            'status': 'registration'
        }
        
        supabase.table('tournaments').update(update_data).eq('id', tournament_id).execute()
        print(f"🔄 Reset tournament status to registration")
        
        print(f"✅ Tournament '{tournament_name}' is ready for bracket regeneration")
        return True
        
    except Exception as e:
        print(f"❌ Error clearing matches: {e}")
        return False

if __name__ == "__main__":
    clear_matches_only("sabo1")