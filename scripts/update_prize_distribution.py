#!/usr/bin/env python3
"""Update prize distribution for POOL 9 BALL RANK I-K tournament"""

import os
import json
import psycopg2
from dotenv import load_dotenv

load_dotenv()

def main():
    conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
    cur = conn.cursor()

    # Define custom prize distribution as per user request:
    # Champions: 1.000.000 VNĐ + 500k Voucher
    # Runner-up: 400.000 VNĐ + 300k Voucher
    # 3rd Place (x2): 100.000 VNĐ + 150k Voucher
    # Top 5-8: Voucher 50k
    custom_distribution = {
        'source': 'sponsor',
        'template': 'custom',
        'organizerFeePercent': 0,
        'sponsorContribution': 1600000,
        'totalPrizePool': 1600000,
        'distribution': [
            {'position': 1, 'cashAmount': 1000000, 'voucherAmount': 500000, 'percentage': 62.5},
            {'position': 2, 'cashAmount': 400000, 'voucherAmount': 300000, 'percentage': 25},
            {'position': 3, 'cashAmount': 100000, 'voucherAmount': 150000, 'percentage': 6.25},
            {'position': 4, 'cashAmount': 100000, 'voucherAmount': 150000, 'percentage': 6.25},
            {'position': 5, 'cashAmount': 0, 'voucherAmount': 50000, 'percentage': 0},
            {'position': 6, 'cashAmount': 0, 'voucherAmount': 50000, 'percentage': 0},
            {'position': 7, 'cashAmount': 0, 'voucherAmount': 50000, 'percentage': 0},
            {'position': 8, 'cashAmount': 0, 'voucherAmount': 50000, 'percentage': 0},
        ]
    }

    # Update the tournament
    cur.execute('''
        UPDATE tournaments 
        SET prize_distribution = %s,
            updated_at = NOW()
        WHERE title = 'POOL 9 BALL RANK I-K'
        RETURNING id, title
    ''', (json.dumps(custom_distribution),))

    result = cur.fetchone()
    conn.commit()

    if result:
        print(f'✅ Updated tournament: {result[1]}')
        print(f'   ID: {result[0]}')
        print(f'   Prize Distribution: custom')
        print()
        print('🥇 New Prize Structure:')
        print('   • 1st: 1,000,000 VND + 500k Voucher')
        print('   • 2nd: 400,000 VND + 300k Voucher')
        print('   • 3rd: 100,000 VND + 150k Voucher (x2)')
        print('   • 5th-8th: 50k Voucher')
    else:
        print('❌ Tournament not found')

    conn.close()

if __name__ == '__main__':
    main()
