import os
import psycopg2
from dotenv import load_dotenv
load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
cur = conn.cursor()

# Check game_format values
cur.execute("SELECT DISTINCT game_format FROM tournaments WHERE game_format IS NOT NULL LIMIT 10")
print("Game formats:", [r[0] for r in cur.fetchall()])

# Check constraint definition
cur.execute("""
    SELECT pg_get_constraintdef(oid) 
    FROM pg_constraint 
    WHERE conname = 'check_game_format'
""")
result = cur.fetchone()
if result:
    print("\nConstraint definition:", result[0])

conn.close()
