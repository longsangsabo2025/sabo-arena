#!/usr/bin/env python3
"""
🔍 Check Club Owner
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

CLUB_ID = 'dde4b08a-bece-4304-ad2b-fd5dec658b3f'
CURRENT_USER_ID = 'dcca23f3-ad27-4954-935b-9bf66ea4b7ce'

def check_club_owner():
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
    
    print('🔍 Checking Club Owner...\n')
    
    cur.execute("SELECT id, name, owner_id FROM clubs WHERE id = %s", (CLUB_ID,))
    club = cur.fetchone()
    
    if not club:
        print('❌ Club not found!')
        return
    
    club_id, name, owner_id = club
    print(f'🏟️ Club: {name}')
    print(f'   ID: {club_id}')
    print(f'   Owner ID: {owner_id}')
    print(f'   Current User ID: {CURRENT_USER_ID}')
    
    if owner_id == CURRENT_USER_ID:
        print('✅ Current user IS the owner.')
    else:
        print('❌ Current user is NOT the owner.')
        
        # Update owner if needed
        print('\n🔄 Updating owner to current user...')
        try:
            cur.execute("UPDATE clubs SET owner_id = %s WHERE id = %s", (CURRENT_USER_ID, CLUB_ID))
            conn.commit()
            print('✅ Owner updated successfully!')
        except Exception as e:
            print(f'❌ Failed to update owner: {e}')

    cur.close()
    conn.close()

if __name__ == "__main__":
    check_club_owner()
