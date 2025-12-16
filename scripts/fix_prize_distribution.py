#!/usr/bin/env python3
"""Fix prize distribution for POOL 9 BALL RANK I-K tournament"""

import os
import json
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
cur = conn.cursor()

# Custom prize distribution theo yêu cầu
prize_distribution = json.dumps({
    "first": "1.000.000 VNĐ + 500k Voucher + Bảng vinh danh",
    "second": "400.000 VNĐ + 300k Voucher + Bảng vinh danh", 
    "third": "100.000 VNĐ + 150k Voucher + Bảng vinh danh",
    "fourth": "100.000 VNĐ + 150k Voucher + Bảng vinh danh",
    "fifth_to_eighth": "Voucher 50k"
})

# Update tournament
cur.execute("""
    UPDATE tournaments 
    SET prize_distribution = %s
    WHERE title = 'POOL 9 BALL RANK I-K'
    RETURNING id, title
""", (prize_distribution,))

result = cur.fetchone()
if result:
    print(f"✅ Updated prize distribution for: {result[1]}")
    print(f"   ID: {result[0]}")
else:
    print("❌ Tournament not found")

conn.commit()
cur.close()
conn.close()
