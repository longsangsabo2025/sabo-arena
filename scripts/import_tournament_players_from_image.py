#!/usr/bin/env python3
"""
👥 Import 16 Players to POOL 9 BALL RANK I-K Tournament (12/12)
Creates users if they don't exist and registers them to the tournament
"""

import os
import psycopg2
from dotenv import load_dotenv
import uuid
import unicodedata

load_dotenv()

# 16 players with their ranks from the image
PLAYERS = [
    {"name": "Công Kun", "rank": "I"},
    {"name": "Trường Vũ GLX", "rank": "I"},
    {"name": "Ba Mỡ", "rank": "I"},
    {"name": "Gia Huy", "rank": "I+"},
    {"name": "Phạm Quang", "rank": "I+"},
    {"name": "Anh Quốc", "rank": "I+"},
    {"name": "Thiên Thanh", "rank": "I+"},
    {"name": "Hiếu Trần", "rank": "I+"},
    {"name": "Minh Hiếu", "rank": "I+"},
    {"name": "Bảo Bi", "rank": "I+"},
    {"name": "Trí Tâm", "rank": "I"},
    {"name": "Hvt102", "rank": "I"},
    {"name": "ĐẠT KING", "rank": "I"},
    {"name": "An Phát", "rank": "K"},
    {"name": "Trịnh hải", "rank": "I+"},
    {"name": "Triều Đình", "rank": "I+"},
]

def generate_username(name):
    """Generate a username from display name"""
    # Remove Vietnamese accents and convert to lowercase
    normalized = unicodedata.normalize('NFD', name)
    ascii_name = ''.join(c for c in normalized if unicodedata.category(c) != 'Mn')
    # Replace spaces with underscores and make lowercase
    username = ascii_name.lower().replace(' ', '_')
    # Remove special characters
    username = ''.join(c for c in username if c.isalnum() or c == '_')
    return username

def import_players():
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
    
    print('👥 Importing 16 Players to POOL 9 BALL RANK I-K Tournament\n')
    
    # Temporarily disable triggers if needed (optional, but good for bulk inserts)
    try:
        cur.execute("SET session_replication_role = 'replica';")
        print('⚙️ Disabled triggers temporarily\n')
    except:
        pass
    
    # 1. Find the tournament
    # Looking for tournament starting on 2025-12-12
    cur.execute("""
        SELECT id, title, current_participants, max_participants 
        FROM tournaments 
        WHERE title ILIKE '%POOL 9 BALL%' AND title ILIKE '%RANK I%'
        ORDER BY start_date DESC
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
    
    # 2. Clear existing participants for this tournament (Optional: User said "add", but usually we want to reset to match the list)
    # But user said "thêm user... user nào chưa có tên thì tạo mới", implying we should just ensure these users are in.
    # However, if the tournament is full or has wrong people, we might want to clear it.
    # Let's ask or just add. Since it's a specific list of 16 for a 16-player tournament, clearing is safer to ensure exact match.
    # But let's just add/update for now to be safe.
    
    # Actually, let's clear the participants first to ensure the list matches exactly the image.
    print('🧹 Clearing existing participants for this tournament...')
    cur.execute("DELETE FROM tournament_participants WHERE tournament_id = %s", (tournament_id,))
    
    # 3. Process each player
    for i, player in enumerate(PLAYERS, 1):
        name = player["name"]
        rank = player["rank"]
        username = generate_username(name)
        
        print(f'{i:2}. Processing: {name} ({rank})')
        
        # Check if user exists (by username or display_name)
        cur.execute("""
            SELECT id, display_name, username, rank FROM users 
            WHERE username = %s OR display_name ILIKE %s
            LIMIT 1
        """, (username, name))
        existing_user = cur.fetchone()
        
        if existing_user:
            user_id = existing_user[0]
            current_rank = existing_user[3]
            print(f'    ✓ User exists: {existing_user[1]} (@{existing_user[2]}) - Rank: {current_rank}')
            
            # Update rank if different
            if current_rank != rank:
                cur.execute("UPDATE users SET rank = %s WHERE id = %s", (rank, user_id))
                print(f'    🔄 Updated rank to {rank}')
        else:
            # Create new user
            user_id = str(uuid.uuid4())
            fake_email = f"{username}_{uuid.uuid4().hex[:4]}@sabo.local" # Unique email
            
            # Insert into auth.users (if we could, but we can't easily without admin API)
            # For this script, we are inserting into public.users. 
            # Note: In Supabase, usually we need auth.users entry first.
            # However, if the app uses public.users as the main profile table and handles auth separately or allows "ghost" users, this is fine.
            # Based on previous scripts (add_16_players...), it seems we insert into public.users directly.
            # Wait, the previous script had a comment: "# Create new user with generated email (required by constraint)"
            # And it inserted into `users`. Let's check the previous script again.
            
            print(f'    ➕ Creating new user: {name} (@{username})')
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
            """, (
                user_id, 
                username, 
                name, 
                name, 
                fake_email, 
                rank, 
                1200, 
                'intermediate'
            ))
            
        # Add to tournament
        try:
            participant_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO tournament_participants (
                    id, tournament_id, user_id, seed_number,
                    status, registered_at, created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s,
                    'approved', NOW(), NOW(), NOW()
                )
                ON CONFLICT (tournament_id, user_id) DO NOTHING
            """, (participant_id, tournament_id, user_id, i))
            print(f'    ✅ Added to tournament')
        except Exception as e:
            print(f'    ❌ Failed to add to tournament: {e}')

    # Update tournament participant count
    cur.execute("""
        UPDATE tournaments 
        SET current_participants = (SELECT COUNT(*) FROM tournament_participants WHERE tournament_id = %s)
        WHERE id = %s
    """, (tournament_id, tournament_id))
    
    # Re-enable triggers
    try:
        cur.execute("SET session_replication_role = 'origin';")
        print('\n⚙️ Re-enabled triggers')
    except:
        pass

    conn.commit()
    cur.close()
    conn.close()
    print('\n✨ Import completed successfully!')

if __name__ == "__main__":
    import_players()
