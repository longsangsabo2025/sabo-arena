#!/usr/bin/env python3
"""Check challenge_configurations"""

import json
import psycopg2

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'], connect_timeout=10)
cursor = conn.cursor()

cursor.execute("SELECT bet_amount FROM challenge_configurations ORDER BY bet_amount")
results = cursor.fetchall()

print("Available bet_amounts in challenge_configurations:")
for row in results:
    print(f"  • {row[0]}")

cursor.close()
conn.close()
