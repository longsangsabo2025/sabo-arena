#!/usr/bin/env python3
"""
🔄 Update POOL 9 BALL RANK I-K Tournament
- Clear all matches
- Update player list with new 16 players
"""

import os
import psycopg2
from dotenv import load_dotenv
import uuid

load_dotenv()

TOURNAMENT_ID = 'e555beb9-9b15-4b01-b299-fb95863b76d4'

# New player list from image - 16 players with ranks
PLAYERS = [
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

def update_tournament():
    conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
    cur = conn.cursor()
    
    print(f'🔄 Updating Tournament: {TOURNAMENT_ID}\n')
    
    # 1. Clear all matches for this tournament
    print('🗑️ Clearing existing matches...')
    
    # Try bracket_matches first (if exists)
    try:
        cur.execute("""
            DELETE FROM bracket_matches WHERE tournament_id = %s
        """, (TOURNAMENT_ID,))
        deleted_bracket = cur.rowcount
        print(f'   Deleted {deleted_bracket} bracket_matches')
    except:
        conn.rollback()
        print('   bracket_matches table does not exist, skipping...')
    
    cur.execute("""
        DELETE FROM matches WHERE tournament_id = %s
    """, (TOURNAMENT_ID,))
    deleted_matches = cur.rowcount
    print(f'   Deleted {deleted_matches} matches')
    
    # 2. Clear existing participants
    print('\n🗑️ Clearing existing participants...')
    cur.execute("""
        DELETE FROM tournament_participants WHERE tournament_id = %s
    """, (TOURNAMENT_ID,))
    deleted_participants = cur.rowcount
    print(f'   Deleted {deleted_participants} participants')
    
    # 3. Create/update profiles and add as participants
    print('\n👥 Adding new players...')
    
    for i, (name, rank) in enumerate(PLAYERS, 1):
        # Generate avatar URL using DiceBear
        avatar_seed = name.replace(' ', '_').lower()
        avatar_url = f"https://api.dicebear.com/7.x/avataaars/svg?seed={avatar_seed}"
        
        # Check if user exists by full_name or display_name
        cur.execute("""
            SELECT id FROM users WHERE full_name = %s OR display_name = %s LIMIT 1
        """, (name, name))
        user = cur.fetchone()
        
        if user:
            user_id = user[0]
            # Update avatar and rank if needed
            cur.execute("""
                UPDATE users SET avatar_url = %s, rank = %s, updated_at = NOW() WHERE id = %s
            """, (avatar_url, rank, user_id))
            print(f'   {i:2d}. {name} (Hạng {rank}) - Updated existing user')
        else:
            # Create new user - need email for contact_check constraint
            user_id = str(uuid.uuid4())
            username = name.lower().replace(' ', '_').replace('+', 'plus')
            email = f"{username}@sabo-arena.local"
            cur.execute("""
                INSERT INTO users (id, email, full_name, display_name, username, avatar_url, rank, role, skill_level, is_verified, is_active, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, 'player', 'intermediate', false, true, NOW(), NOW())
            """, (user_id, email, name, name, username, avatar_url, rank))
            print(f'   {i:2d}. {name} (Hạng {rank}) - Created new user')
        
        # Add to tournament_participants
        cur.execute("""
            INSERT INTO tournament_participants (tournament_id, user_id, seed_number, status, created_at)
            VALUES (%s, %s, %s, 'registered', NOW())
            ON CONFLICT (tournament_id, user_id) DO UPDATE SET seed_number = %s
        """, (TOURNAMENT_ID, user_id, i, i))
    
    # 4. Update tournament status to 'upcoming' (ready for bracket generation)
    cur.execute("""
        UPDATE tournaments SET status = 'upcoming', updated_at = NOW() WHERE id = %s
    """, (TOURNAMENT_ID,))
    
    conn.commit()
    
    print('\n' + '='*60)
    print('✅ TOURNAMENT UPDATED SUCCESSFULLY!')
    print('='*60)
    print(f'\n📋 Tournament ID: {TOURNAMENT_ID}')
    print(f'👥 Players: {len(PLAYERS)}')
    print('\n📝 Player List:')
    for i, (name, rank) in enumerate(PLAYERS, 1):
        print(f'   {i:2d}. {name} - Hạng {rank}')
    
    print('\n🎯 Next steps:')
    print('   1. Open SABO Arena app')
    print('   2. Go to tournament details')
    print('   3. Start tournament to generate bracket')
    
    cur.close()
    conn.close()

if __name__ == '__main__':
    try:
        update_tournament()
    except Exception as e:
        print(f'\n❌ ERROR: {e}')
        import traceback
        traceback.print_exc()
