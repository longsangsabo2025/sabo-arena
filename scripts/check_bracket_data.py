#!/usr/bin/env python3
"""
🔍 Check Tournament Bracket Data
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

def check_bracket():
    conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
    cur = conn.cursor()
    
    print('🔍 Checking Tournament Bracket Data\n')
    
    # 1. Find tournament
    cur.execute("""
        SELECT id, title, status, bracket_format, current_participants, max_participants
        FROM tournaments 
        WHERE title ILIKE '%POOL 9 BALL RANK I-K%'
        ORDER BY created_at DESC
        LIMIT 1
    """)
    tournament = cur.fetchone()
    
    if not tournament:
        print('❌ Tournament not found!')
        return
    
    t_id, title, status, bracket_format, current, max_p = tournament
    print(f'🏆 Tournament: {title}')
    print(f'   ID: {t_id}')
    print(f'   Status: {status}')
    print(f'   Format: {bracket_format}')
    print(f'   Participants: {current}/{max_p}')
    
    # 2. Check matches with full details
    print(f'\n🎯 Matches (detailed):')
    cur.execute("""
        SELECT 
            m.match_number, 
            m.round, 
            m.bracket_type,
            m.bracket_group,
            m.round_number,
            m.status,
            u1.display_name as p1_name,
            u2.display_name as p2_name
        FROM matches m
        LEFT JOIN users u1 ON u1.id = m.player1_id
        LEFT JOIN users u2 ON u2.id = m.player2_id
        WHERE m.tournament_id = %s
        ORDER BY m.match_number
    """, (t_id,))
    matches = cur.fetchall()
    
    if matches:
        print(f'   Total: {len(matches)} matches\n')
        for m in matches:
            match_num, round_str, bracket_type, bracket_group, round_num, status, p1, p2 = m
            p1_display = p1 or 'TBD'
            p2_display = p2 or 'TBD'
            print(f'   M{match_num:2}: {bracket_type or "?":<5} | Group: {bracket_group or "None":<5} | Round: {round_num or "?"} | {status:<12} | {p1_display} vs {p2_display}')
    else:
        print('   ❌ No matches found!')
    
    # Check unique bracket_type and bracket_group values
    print(f'\n📊 Unique values:')
    cur.execute("""
        SELECT DISTINCT bracket_type FROM matches WHERE tournament_id = %s
    """, (t_id,))
    types = [r[0] for r in cur.fetchall()]
    print(f'   bracket_type: {types}')
    
    cur.execute("""
        SELECT DISTINCT bracket_group FROM matches WHERE tournament_id = %s
    """, (t_id,))
    groups = [r[0] for r in cur.fetchall()]
    print(f'   bracket_group: {groups}')
    
    cur.close()
    conn.close()

if __name__ == '__main__':
    try:
        check_bracket()
    except Exception as e:
        print(f'\n❌ ERROR: {e}')
        import traceback
        traceback.print_exc()
