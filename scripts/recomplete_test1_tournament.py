#!/usr/bin/env python3
"""
Re-complete test1 tournament với bracket-based logic mới
Xóa tournament_results cũ và chạy lại completion flow
"""

import os
import sys
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

TOURNAMENT_ID = 'test1'

def main():
    print(f"🔄 Re-completing tournament: {TOURNAMENT_ID}")
    
    # Step 1: Delete existing tournament_results
    print(f"\n1️⃣ Deleting old tournament_results for {TOURNAMENT_ID}...")
    try:
        result = supabase.table('tournament_results').delete().eq('tournament_id', TOURNAMENT_ID).execute()
        deleted_count = len(result.data) if result.data else 0
        print(f"   ✅ Deleted {deleted_count} old results")
    except Exception as e:
        print(f"   ⚠️ Error deleting: {e}")
    
    # Step 2: Update tournament status back to 'active'
    print(f"\n2️⃣ Setting tournament status to 'active'...")
    try:
        supabase.table('tournaments').update({
            'status': 'active'
        }).eq('id', TOURNAMENT_ID).execute()
        print(f"   ✅ Tournament status updated to 'active'")
    except Exception as e:
        print(f"   ❌ Error updating status: {e}")
        sys.exit(1)
    
    print(f"\n✅ DONE! Tournament {TOURNAMENT_ID} is ready to be re-completed")
    print(f"\n📋 Next steps:")
    print(f"   1. Open tournament detail page in app")
    print(f"   2. Click 'Complete Tournament' button")
    print(f"   3. Verify rankings show correct bracket positions:")
    print(f"      - Rank 1: Finals winner (gold)")
    print(f"      - Rank 2: Finals loser (silver)")
    print(f"      - Rank 3: Semi-finals losers (bronze, tie rank)")
    print(f"      - Rank 5+: Quarter-finals losers (white)")

if __name__ == '__main__':
    main()
