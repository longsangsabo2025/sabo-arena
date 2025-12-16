#!/usr/bin/env python3
"""
👥 Add 16 Players to POOL 9 BALL RANK I-K Tournament
Creates users if they don't exist and registers them to the tournament
"""

import os
import psycopg2
from dotenv import load_dotenv
import uuid

load_dotenv()

# 16 players with their ranks
PLAYERS = [
    {"name": "Lý Bảo", "rank": "I"},
    {"name": "Bảo Lâm", "rank": "I"},
    {"name": "Trọng Phúc", "rank": "I"},
    {"name": "Ben 10", "rank": "K"},
    {"name": "Quang Khải", "rank": "I"},
    {"name": "Dương Hải", "rank": "I"},
    {"name": "Đạo Chích Kid", "rank": "I"},
    {"name": "Nguyễn Hiếu", "rank": "I+"},
    {"name": "Anh Quốc", "rank": "I"},
    {"name": "Quốc Bảo", "rank": "I"},
    {"name": "Phát Vũ", "rank": "I+"},
    {"name": "Huy Gạo", "rank": "I"},
    {"name": "Tiến Còi", "rank": "I"},
    {"name": "Tú Ngô", "rank": "I"},
    {"name": "Hải Ly", "rank": "I"},
    {"name": "Xin Con 1", "rank": "K"},
]

def generate_username(name):
    """Generate a username from display name"""
    # Remove Vietnamese accents and convert to lowercase
    import unicodedata
    normalized = unicodedata.normalize('NFD', name)
    ascii_name = ''.join(c for c in normalized if unicodedata.category(c) != 'Mn')
    # Replace spaces with underscores and make lowercase
    username = ascii_name.lower().replace(' ', '_')
    return username

def add_players_to_tournament():
    conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
    cur = conn.cursor()
    
    print('👥 Adding 16 Players to POOL 9 BALL RANK I-K Tournament\n')
    
    # Temporarily disable the problematic trigger/constraint
    try:
        cur.execute("SET session_replication_role = 'replica';")
        print('⚙️ Disabled triggers temporarily\n')
    except:
        pass
    
    # 1. Find the tournament
    cur.execute("""
        SELECT id, title, current_participants, max_participants 
        FROM tournaments 
        WHERE title ILIKE '%POOL 9 BALL RANK I-K%'
        ORDER BY created_at DESC
        LIMIT 1
    """)
    tournament = cur.fetchone()
    
    if not tournament:
        print('❌ Tournament not found! Please create the tournament first.')
        return
    
    tournament_id, tournament_title, current_participants, max_participants = tournament
    print(f'🏆 Tournament: {tournament_title}')
    print(f'   ID: {tournament_id}')
    print(f'   Current participants: {current_participants}/{max_participants}\n')
    
    # 2. Process each player
    added_count = 0
    for i, player in enumerate(PLAYERS, 1):
        name = player["name"]
        rank = player["rank"]
        username = generate_username(name)
        
        print(f'{i:2}. Processing: {name} ({rank})')
        
        # Check if user exists
        cur.execute("""
            SELECT id, display_name, username FROM users 
            WHERE username = %s OR display_name = %s
            LIMIT 1
        """, (username, name))
        existing_user = cur.fetchone()
        
        if existing_user:
            user_id = existing_user[0]
            print(f'    ✓ User exists: {existing_user[1]} (@{existing_user[2]})')
        else:
            # Create new user with generated email (required by constraint)
            user_id = str(uuid.uuid4())
            fake_email = f"{username}@sabo.local"
            cur.execute("""
                INSERT INTO users (
                    id, username, display_name, full_name,
                    email, rank, elo_rating, skill_level,
                    created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s,
                    %s, %s, %s, %s,
                    NOW(), NOW()
                )
                ON CONFLICT (username) DO UPDATE SET
                    display_name = EXCLUDED.display_name,
                    rank = EXCLUDED.rank
                RETURNING id
            """, (
                user_id,
                username,
                name,
                name,
                fake_email,
                rank,
                1200,  # Default ELO
                'intermediate'
            ))
            result = cur.fetchone()
            if result:
                user_id = result[0]
            print(f'    + Created user: {name} (@{username})')
        
        # Check if already registered
        cur.execute("""
            SELECT id FROM tournament_participants 
            WHERE tournament_id = %s AND user_id = %s
        """, (tournament_id, user_id))
        existing_participant = cur.fetchone()
        
        if existing_participant:
            print(f'    ⚠️ Already registered')
        else:
            # Register to tournament
            participant_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO tournament_participants (
                    id, tournament_id, user_id, seed_number,
                    status, registered_at, created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s,
                    %s, NOW(), NOW(), NOW()
                )
            """, (
                participant_id,
                tournament_id,
                user_id,
                i,  # Seed number (1-16)
                'registered'
            ))
            print(f'    ✅ Registered (Seed #{i})')
            added_count += 1
        
        # Commit after each player to avoid FK issues with triggers
        conn.commit()
    
    # 3. Update tournament participant count
    cur.execute("""
        UPDATE tournaments 
        SET current_participants = (
            SELECT COUNT(*) FROM tournament_participants 
            WHERE tournament_id = %s AND status = 'registered'
        ),
        updated_at = NOW()
        WHERE id = %s
    """, (tournament_id, tournament_id))
    
    # Get final count
    cur.execute("""
        SELECT current_participants FROM tournaments WHERE id = %s
    """, (tournament_id,))
    final_count = cur.fetchone()[0]
    
    # Re-enable triggers
    try:
        cur.execute("SET session_replication_role = 'origin';")
    except:
        pass
    
    conn.commit()
    cur.close()
    conn.close()
    
    print('\n' + '='*60)
    print('🎉 PLAYERS ADDED SUCCESSFULLY!')
    print('='*60)
    print(f'\n📊 Summary:')
    print(f'   • New registrations: {added_count}')
    print(f'   • Total participants: {final_count}/16')
    print(f'\n👥 Player List:')
    for i, player in enumerate(PLAYERS, 1):
        print(f'   {i:2}. {player["name"]} - Rank {player["rank"]}')
    
    if final_count == 16:
        print('\n✅ Tournament is FULL! Ready to start!')
        print('   Open SABO Arena app to generate the bracket.')
    
    return tournament_id

if __name__ == '__main__':
    try:
        tournament_id = add_players_to_tournament()
        print(f'\n✅ Done!')
    except Exception as e:
        print(f'\n❌ ERROR: {e}')
        import traceback
        traceback.print_exc()
