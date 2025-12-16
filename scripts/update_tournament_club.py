#!/usr/bin/env python3
"""
🏟️ Update Tournament Club to SABO Billiards
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# SABO Billiards Club ID (from logs)
CLUB_ID = 'dde4b08a-bece-4304-ad2b-fd5dec658b3f'

def update_tournament_club():
    db_url = os.getenv('SUPABASE_DB_TRANSACTION_URL')
    if not db_url:
        print("❌ Error: SUPABASE_DB_TRANSACTION_URL not found in .env")
        return

    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
    except Exception as e:
        print(f"❌ Error connecting to database: {e}")
        return
    
    print('🏟️ Updating Tournament Club...\n')
    
    # 1. Find the tournament
    cur.execute("""
        SELECT id, title, club_id
        FROM tournaments 
        WHERE title ILIKE '%POOL 9 BALL%' AND title ILIKE '%RANK I%'
        ORDER BY start_date DESC
        LIMIT 1
    """)
    tournament = cur.fetchone()
    
    if not tournament:
        print('❌ Tournament not found!')
        return
    
    tournament_id, title, current_club_id = tournament
    print(f'🏆 Tournament: {title}')
    print(f'   ID: {tournament_id}')
    print(f'   Current Club ID: {current_club_id}')
    
    # 2. Update Club ID
    if current_club_id != CLUB_ID:
        try:
            cur.execute("""
                UPDATE tournaments 
                SET club_id = %s 
                WHERE id = %s
            """, (CLUB_ID, tournament_id))
            conn.commit()
            print(f'✅ Updated club to SABO Billiards ({CLUB_ID})')
        except Exception as e:
            print(f'❌ Failed to update club: {e}')
    else:
        print('✅ Already assigned to SABO Billiards')

    cur.close()
    conn.close()

if __name__ == "__main__":
    update_tournament_club()
