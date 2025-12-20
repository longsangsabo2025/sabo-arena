#!/usr/bin/env python3
"""
🚀 ELON MODE: Force re-complete tournament with NEW bracket-based logic
Deletes old tournament_results and resets tournament status to trigger re-completion
"""

import os
import sys
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Missing credentials in .env")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def reset_tournament_for_recompletion(tournament_id: str):
    """Reset tournament to allow re-completion with new bracket logic"""
    print(f"\n🔄 Resetting tournament: {tournament_id}")
    
    try:
        # Step 1: Delete old tournament_results (old rankings)
        print(f"1️⃣ Deleting old tournament_results...")
        result = supabase.table('tournament_results').delete().eq('tournament_id', tournament_id).execute()
        deleted_count = len(result.data) if result.data else 0
        print(f"   ✅ Deleted {deleted_count} old result records")
        
        # Step 2: Reset tournament status to 'active'
        print(f"2️⃣ Setting tournament status back to 'active'...")
        supabase.table('tournaments').update({
            'status': 'active',
            'completed_at': None,
            'updated_at': 'now()'
        }).eq('id', tournament_id).execute()
        print(f"   ✅ Tournament status reset to 'active'")
        
        # Step 3: Show instructions
        print(f"\n✅ DONE! Tournament {tournament_id} ready for re-completion")
        print(f"\n📋 Next steps:")
        print(f"   1. Go to app → Tournament Rankings tab")
        print(f"   2. Click '🏆 Complete Tournament' button (orange, top right)")
        print(f"   3. Confirm completion")
        print(f"   4. Watch NEW bracket-based rankings appear! 🎯")
        print(f"\n🎯 Expected results:")
        print(f"   - Finals winner → Rank 1 (gold)")
        print(f"   - Finals loser → Rank 2 (silver)")
        print(f"   - Semi-finals losers → Rank 3 (bronze, ALL TIE)")
        print(f"   - Quarter-finals losers → Rank 5+ (white)")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    # Default tournament
    tournament_id = 'test1'
    
    # Allow custom tournament ID
    if len(sys.argv) > 1:
        tournament_id = sys.argv[1]
    
    print(f"🚀 ELON MODE: Force Tournament Re-completion")
    print(f"=" * 60)
    
    confirm = input(f"\n⚠️ Reset tournament '{tournament_id}' for re-completion? (y/N): ")
    if confirm.lower() != 'y':
        print("Cancelled.")
        sys.exit(0)
    
    reset_tournament_for_recompletion(tournament_id)
