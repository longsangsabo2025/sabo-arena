#!/usr/bin/env python3
"""
Script to update tournament status to completed when all matches are finished
"""

import os
from supabase import create_client, Client
from datetime import datetime
import json

# Supabase credentials
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

def main():
    print("🔄 Updating tournament status to completed...")
    
    # Initialize Supabase client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # Tournament ID for sabo1
    tournament_id = "a55163bd-c60b-42b1-840d-8719363096f5"
    
    try:
        # First check tournament current status
        tournament_response = supabase.table('tournaments').select('*').eq('id', tournament_id).execute()
        
        if not tournament_response.data:
            print("❌ Tournament not found!")
            return
            
        tournament = tournament_response.data[0]
        print(f"📊 Current tournament status: {tournament['status']}")
        print(f"   Title: {tournament['title']}")
        print(f"   Max participants: {tournament['max_participants']}")
        
        # Check if all matches are completed
        matches_response = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
        matches = matches_response.data
        
        total_matches = len(matches)
        completed_matches = len([m for m in matches if m['status'] == 'completed'])
        
        print(f"📈 Match status: {completed_matches}/{total_matches} completed")
        
        if completed_matches == total_matches and total_matches > 0:
            # All matches completed, update tournament status
            print("✅ All matches completed! Updating tournament status...")
            
            update_data = {
                'status': 'completed',
                'updated_at': datetime.utcnow().isoformat()
            }
            
            # Update tournament
            result = supabase.table('tournaments').update(update_data).eq('id', tournament_id).execute()
            
            if result.data:
                print("🏆 Tournament status updated to 'completed'!")
                print(f"   Updated at: {update_data['updated_at']}")
                
                # Show final champion
                final_match = max(matches, key=lambda x: int(x['round_number']) if x['round_number'] else 0)
                if final_match and final_match['winner_id']:
                    winner_response = supabase.table('users').select('username, full_name').eq('id', final_match['winner_id']).execute()
                    if winner_response.data:
                        winner = winner_response.data[0]
                        winner_name = winner['full_name'] or winner['username']
                        print(f"🥇 CHAMPION: {winner_name} ({final_match['winner_id'][:8]}...)")
                        print(f"   Final match scores: {final_match['player1_score']}-{final_match['player2_score']}")
                
            else:
                print("❌ Failed to update tournament status")
                
        else:
            print(f"⚠️  Tournament not ready for completion:")
            print(f"   Completed matches: {completed_matches}/{total_matches}")
            
            # Show pending matches
            pending_matches = [m for m in matches if m['status'] != 'completed']
            if pending_matches:
                print("📋 Pending matches:")
                for match in pending_matches:
                    print(f"   - Round {match['round_number']}: {match['match_name']} - Status: {match['status']}")
                    
    except Exception as e:
        print(f"❌ Error updating tournament: {str(e)}")

if __name__ == "__main__":
    main()