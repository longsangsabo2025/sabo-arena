#!/usr/bin/env python3
"""
🖼️ Add Avatars to Tournament Players
Updates avatar_url for all players in POOL 9 BALL RANK I-K
"""

import os
import psycopg2
from dotenv import load_dotenv
import hashlib

load_dotenv()

# Avatar styles to use (DiceBear API)
# Styles: adventurer, avataaars, big-smile, bottts, croodles, fun-emoji, lorelei, micah, miniavs, notionists, open-peeps, personas, pixel-art, thumbs
AVATAR_STYLES = [
    'adventurer',
    'avataaars', 
    'big-smile',
    'lorelei',
    'micah',
    'notionists',
    'open-peeps',
    'thumbs'
]

def generate_avatar_url(name, seed=None):
    """Generate avatar URL using DiceBear API"""
    import random
    style = random.choice(AVATAR_STYLES)
    # Use name as seed for consistent avatars
    seed_value = seed or name.replace(' ', '-')
    return f"https://api.dicebear.com/7.x/{style}/svg?seed={seed_value}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf"

def update_player_avatars():
    conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
    cur = conn.cursor()
    
    print('🖼️ Adding Avatars to Tournament Players\n')
    
    # Find players in the tournament
    cur.execute("""
        SELECT u.id, u.display_name, u.username, u.avatar_url
        FROM users u
        JOIN tournament_participants tp ON tp.user_id = u.id
        JOIN tournaments t ON t.id = tp.tournament_id
        WHERE t.title ILIKE '%POOL 9 BALL RANK I-K%'
        ORDER BY tp.seed_number
    """)
    players = cur.fetchall()
    
    if not players:
        print('❌ No players found in tournament!')
        return
    
    print(f'Found {len(players)} players\n')
    
    updated_count = 0
    for i, (user_id, display_name, username, current_avatar) in enumerate(players, 1):
        # Generate new avatar
        avatar_url = generate_avatar_url(display_name or username, seed=str(i))
        
        # Update user
        cur.execute("""
            UPDATE users 
            SET avatar_url = %s, updated_at = NOW()
            WHERE id = %s
        """, (avatar_url, user_id))
        
        status = "🔄 Updated" if current_avatar else "✅ Added"
        print(f'{i:2}. {display_name or username}: {status}')
        print(f'    {avatar_url[:60]}...')
        updated_count += 1
    
    conn.commit()
    cur.close()
    conn.close()
    
    print('\n' + '='*60)
    print('🎉 AVATARS ADDED SUCCESSFULLY!')
    print('='*60)
    print(f'\n📊 Updated {updated_count} players with avatars')
    print('\n💡 Tip: Refresh the app to see the new avatars!')

if __name__ == '__main__':
    try:
        update_player_avatars()
        print('\n✅ Done!')
    except Exception as e:
        print(f'\n❌ ERROR: {e}')
        import traceback
        traceback.print_exc()
