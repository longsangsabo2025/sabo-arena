#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Implement basic race to 7 handicap - CORRECT schema"""

import json
import psycopg2

env = json.load(open('env.json'))

try:
    print("Connecting to database...")
    conn = psycopg2.connect(
        env['SUPABASE_DB_TRANSACTION_URL'],
        connect_timeout=10
    )
    print("✅ Connected!")
    cursor = conn.cursor()
    
    print("=" * 70)
    print("BASIC RACE TO 7 HANDICAP - ELON MODE")
    print("=" * 70)
    
    # Step 1: Delete ALL existing rules
    print("\n1️⃣ Clearing existing rules...")
    cursor.execute("DELETE FROM handicap_rules")
    deleted = cursor.rowcount
    conn.commit()  # Commit immediately
    print(f"   ✅ Deleted {deleted} rules")
    
    # Step 2: Insert 9 basic rules (rank_diff 1-9)
    # bet_amount = 0 for basic handicap (sentinel value, not a challenge)
    # handicap_value = rank_difference_value (1:1 mapping)
    
    print("\n2️⃣ Creating basic handicap rules...")
    print("   Logic: rank_difference = handicap_value")
    print("   bet_amount = 0 (sentinel for basic race to 7)")
    
    rules = []
    for diff in range(1, 10):  # 1-9 rank differences
        rules.append({
            'type': f'{diff}_rank',
            'value': diff,
            'bet': 0,  # 0 = basic race to 7 (not a challenge)
            'handicap': float(diff)
        })
    
    insert_query = """
        INSERT INTO handicap_rules 
        (rank_difference_type, rank_difference_value, bet_amount, handicap_value)
        VALUES (%s, %s, %s, %s)
    """
    
    for rule in rules:
        cursor.execute(insert_query, (
            rule['type'],
            rule['value'],
            rule['bet'],
            rule['handicap']
        ))
        print(f"   ✅ Rank diff {rule['value']}: handicap={rule['handicap']}", flush=True)
    
    print("\n   Committing transaction...", flush=True)
    conn.commit()
    print("   ✅ Committed!", flush=True)
    
    # Step 3: Verify
    print("\n3️⃣ Verification...")
    cursor.execute("""
        SELECT rank_difference_type, rank_difference_value, bet_amount, handicap_value
        FROM handicap_rules
        ORDER BY rank_difference_value
    """)
    
    results = cursor.fetchall()
    print(f"   Total rules: {len(results)}\n")
    
    print(f"   {'Type':<12} {'Diff':<6} {'Bet':<10} {'Handicap'}")
    print("   " + "-" * 45)
    for row in results:
        bet_display = 'BASIC(0)' if row[2] == 0 else str(row[2])
        print(f"   {row[0]:<12} {row[1]:<6} {bet_display:<10} {row[3]}")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("✅ BASIC HANDICAP COMPLETE")
    print("=" * 70)
    print("\nUsage:")
    print("  • K(1) vs I(2): diff=1 → 1 ván handicap, race to 7")
    print("  • K(1) vs H(3): diff=2 → 2 ván handicap, race to 7")
    print("  • I(2) vs G(5): diff=3 → 3 ván handicap, race to 7")
    print("\nbet_amount=0 means this is basic race to 7 (NOT challenge/SPA betting)")

except Exception as e:
    print(f"\n❌ ERROR: {e}")
    if conn:
        conn.rollback()
