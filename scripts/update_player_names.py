#!/usr/bin/env python3
"""
🔄 Update player names in tournament
Directly update user names based on seed position
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

TOURNAMENT_ID = 'e555beb9-9b15-4b01-b299-fb95863b76d4'

# New player list from image - 16 players with ranks (by seed order)
NEW_PLAYERS = [
    ("Lý Bảo", "I"),
    ("Bảo Lâm", "I"),
    ("Trọng Phúc", "I"),
    ("Quang Khải", "I"),
    ("Dương Hải", "I"),
    ("Đạo Chích Kid", "I"),
    ("Nguyễn Hiếu", "I+"),
    ("Anh Quốc", "I"),
    ("Quốc Bảo", "I"),
    ("Jayson Trường", "I"),
    ("Huy Cao", "I"),
    ("Tiến Còi", "I"),
    ("Tú Ngô", "I"),
    ("Hải Ly", "I"),
    ("Xìn Con 1", "K"),
    ("Văn Vũ", "I"),
]

def update_player_names():
    conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
    cur = conn.cursor()
    
    print(f'🔄 Updating player names for Tournament: {TOURNAMENT_ID}\n')
    
    # First, clear matches to reset bracket
    print('🗑️ Clearing existing matches...')
    cur.execute("DELETE FROM matches WHERE tournament_id = %s", (TOURNAMENT_ID,))
    print(f'   Deleted {cur.rowcount} matches')
    
    # Get current participants ordered by seed
    cur.execute("""
        SELECT tp.seed_number, tp.user_id, u.full_name, u.display_name
        FROM tournament_participants tp
        JOIN users u ON u.id = tp.user_id
        WHERE tp.tournament_id = %s
        ORDER BY tp.seed_number
    """, (TOURNAMENT_ID,))
    
    participants = cur.fetchall()
    
    print(f'\n👥 Updating {len(participants)} player names...\n')
    print(f"{'Seed':<6} {'Old Name':<25} → {'New Name':<25} {'Rank'}")
    print("-"*75)
    
    for seed, user_id, old_full_name, old_display_name in participants:
        old_name = old_display_name or old_full_name or "N/A"
        
        if seed <= len(NEW_PLAYERS):
            new_name, new_rank = NEW_PLAYERS[seed - 1]
            
            # Generate new avatar
            avatar_seed = new_name.replace(' ', '_').lower()
            avatar_url = f"https://api.dicebear.com/7.x/avataaars/svg?seed={avatar_seed}"
            
            # Update user
            cur.execute("""
                UPDATE users 
                SET full_name = %s, 
                    display_name = %s, 
                    rank = %s,
                    avatar_url = %s,
                    updated_at = NOW()
                WHERE id = %s
            """, (new_name, new_name, new_rank, avatar_url, user_id))
            
            status = "✅" if old_name == new_name else "🔄"
            print(f"{seed:<6} {old_name:<25} → {new_name:<25} {new_rank} {status}")
    
    # Reset tournament status
    cur.execute("""
        UPDATE tournaments SET status = 'upcoming', updated_at = NOW() WHERE id = %s
    """, (TOURNAMENT_ID,))
    
    conn.commit()
    
    print("\n" + "="*75)
    print("✅ PLAYER NAMES UPDATED SUCCESSFULLY!")
    print("="*75)
    print("\n📝 Next steps:")
    print("   1. Open SABO Arena app")
    print("   2. Go to tournament details")
    print("   3. Start tournament to generate new bracket")
    
    cur.close()
    conn.close()

if __name__ == '__main__':
    try:
        update_player_names()
    except Exception as e:
        print(f'\n❌ ERROR: {e}')
        import traceback
        traceback.print_exc()
