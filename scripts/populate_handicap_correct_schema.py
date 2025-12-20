"""
Populate handicap_rules with CORRECT schema
Columns: rank_difference_type, rank_difference_value, bet_amount, handicap_value
"""
import json
import psycopg2

env = json.load(open('env.json'))

try:
    conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
    cursor = conn.cursor()
    
    print("=" * 70)
    print("CLEANING OLD HANDICAP RULES")
    print("=" * 70)
    cursor.execute("DELETE FROM handicap_rules")
    deleted = cursor.rowcount
    print(f"  Deleted {deleted} old rules")
    
    print("\n" + "=" * 70)
    print("POPULATING NEW HANDICAP RULES")
    print("=" * 70)
    
    # Based on challenge_rules_service.dart handicapMatrix
    # rank_difference_type: 1_sub, 1_main, 1.5_main, 2_main
    # rank_difference_value: numeric value (1, 2, 3, 4)
    # bet_amount: in VND (5000, 10000, 20000, 50000, 100000, 200000)
    # handicap_value: handicap points (0.5, 1.0, 1.5, etc.)
    
    rules = [
        # 1 sub-rank difference (±1 level: K vs I, I vs H, etc.)
        # rank_difference_value = 1
        ("1_sub", 1, 5000, 0.5),
        ("1_sub", 1, 10000, 0.5),
        ("1_sub", 1, 20000, 1.0),
        ("1_sub", 1, 50000, 1.0),
        ("1_sub", 1, 100000, 1.5),
        ("1_sub", 1, 200000, 1.5),
        
        # 1 main rank (±2 levels: K vs H, I vs H+, etc.)
        # rank_difference_value = 2
        ("1_main", 2, 5000, 1.0),
        ("1_main", 2, 10000, 1.0),
        ("1_main", 2, 20000, 1.5),
        ("1_main", 2, 50000, 2.0),
        ("1_main", 2, 100000, 2.5),
        ("1_main", 2, 200000, 3.0),
        
        # 1.5 main rank (±3 levels: K vs H+, I vs G, etc.)
        # rank_difference_value = 3
        ("1.5_main", 3, 5000, 1.5),
        ("1.5_main", 3, 10000, 2.0),
        ("1.5_main", 3, 20000, 2.5),
        ("1.5_main", 3, 50000, 3.0),
        ("1.5_main", 3, 100000, 3.5),
        ("1.5_main", 3, 200000, 4.0),
        
        # 2 main ranks (±4 levels: K vs G, I vs G+, etc.)
        # rank_difference_value = 4
        ("2_main", 4, 5000, 2.0),
        ("2_main", 4, 10000, 2.5),
        ("2_main", 4, 20000, 3.0),
        ("2_main", 4, 50000, 4.0),
        ("2_main", 4, 100000, 4.5),
        ("2_main", 4, 200000, 5.0),
    ]
    
    insert_query = """
        INSERT INTO handicap_rules 
        (rank_difference_type, rank_difference_value, bet_amount, handicap_value)
        VALUES (%s, %s, %s, %s)
    """
    
    for rule in rules:
        cursor.execute(insert_query, rule)
        print(f"  [OK] {rule[0]:10s} (val={rule[1]}) | Bet: {rule[2]:6}đ | Handicap: {rule[3]}")
    
    conn.commit()
    
    # Verify
    print("\n" + "=" * 70)
    print("VERIFICATION")
    print("=" * 70)
    cursor.execute("SELECT COUNT(*) FROM handicap_rules")
    count = cursor.fetchone()[0]
    print(f"  Total rules: {count}")
    
    cursor.execute("""
        SELECT rank_difference_type, COUNT(*) 
        FROM handicap_rules 
        GROUP BY rank_difference_type 
        ORDER BY rank_difference_type
    """)
    for row in cursor.fetchall():
        print(f"    {row[0]:10s}: {row[1]} rules")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("[SUCCESS] HANDICAP RULES POPULATED!")
    print("=" * 70)
    
except Exception as e:
    print(f"\nERROR: {e}")
    import traceback
    traceback.print_exc()
    if 'conn' in locals():
        conn.rollback()
        conn.close()
