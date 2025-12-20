"""
Check LIVE schema from Supabase using transaction pooler
"""
import json
import psycopg2

env = json.load(open('env.json'))

try:
    conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
    cursor = conn.cursor()
    
    print("=" * 70)
    print("RANK_SYSTEM TABLE SCHEMA")
    print("=" * 70)
    cursor.execute("""
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'rank_system'
        ORDER BY ordinal_position
    """)
    for col in cursor.fetchall():
        print(f"  {col[0]:25s} | {col[1]:15s} | Null: {col[2]:3s} | Default: {col[3]}")
    
    print("\n" + "=" * 70)
    print("RANK_SYSTEM CURRENT DATA")
    print("=" * 70)
    cursor.execute("""
        SELECT rank_code, rank_order, elo_min, elo_max, rank_name, rank_name_vi
        FROM rank_system
        ORDER BY rank_order
    """)
    for row in cursor.fetchall():
        elo_max = row[3] if row[3] else 'MAX'
        print(f"  {row[1]:2}. {row[0]:3s} | {row[2]}-{elo_max} | {row[4]} / {row[5]}")
    
    print("\n" + "=" * 70)
    print("HANDICAP_RULES TABLE SCHEMA")
    print("=" * 70)
    cursor.execute("""
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'handicap_rules'
        ORDER BY ordinal_position
    """)
    for col in cursor.fetchall():
        print(f"  {col[0]:25s} | {col[1]:15s} | Null: {col[2]:3s} | Default: {col[3]}")
    
    print("\n" + "=" * 70)
    print("HANDICAP_RULES CURRENT DATA (first 5)")
    print("=" * 70)
    cursor.execute("""
        SELECT id, rank_difference_type, bet_amount, handicap_points
        FROM handicap_rules
        ORDER BY id
        LIMIT 5
    """)
    for row in cursor.fetchall():
        print(f"  ID {row[0]:3} | Type: {row[1]:10s} | Bet: {row[2]:6} | Handicap: {row[3]}")
    
    cursor.execute("SELECT COUNT(*) FROM handicap_rules")
    count = cursor.fetchone()[0]
    print(f"\n  Total rules: {count}")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("SCHEMA CHECK COMPLETE")
    print("=" * 70)
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
