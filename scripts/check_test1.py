#!/usr/bin/env python3
"""Check test1 tournament prize pool data"""
import os
import sys
from supabase import create_client
from dotenv import load_dotenv
import json

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Missing Supabase credentials in .env")
    sys.exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Find test1 tournament
response = supabase.table('tournaments').select('*').ilike('title', '%test1%').execute()

if not response.data:
    print("❌ No tournament found with 'test1' in title")
    sys.exit(1)

for tournament in response.data:
    print(f"\n{'='*80}")
    print(f"🏆 Tournament: {tournament['title']}")
    print(f"{'='*80}")
    print(f"ID: {tournament['id']}")
    print(f"Status: {tournament['status']}")
    print(f"\n💰 PRIZE POOL DATA:")
    print(f"  prize_pool (DB field): {tournament.get('prize_pool', 0):,} VND")
    print(f"  entry_fee: {tournament.get('entry_fee', 0):,} VND")
    print(f"  max_participants: {tournament.get('max_participants', 0)}")
    print(f"  current_participants: {tournament.get('current_participants', 0)}")
    
    expected_pool = tournament.get('entry_fee', 0) * tournament.get('max_participants', 0)
    print(f"  📊 Expected from entry fees: {expected_pool:,} VND")
    
    print(f"\n🎁 PRIZE DISTRIBUTION (prize_distribution field):")
    prize_dist = tournament.get('prize_distribution')
    if prize_dist:
        print(f"  Type: {type(prize_dist)}")
        if isinstance(prize_dist, dict):
            print(f"  Keys: {list(prize_dist.keys())}")
            for key, value in prize_dist.items():
                if key == 'totalPrizePool':
                    print(f"  ✨ {key}: {value:,} VND" if isinstance(value, (int, float)) else f"  ✨ {key}: {value}")
                else:
                    print(f"  - {key}: {value}")
        else:
            print(f"  Raw value: {prize_dist}")
    else:
        print("  None")
    
    print(f"\n📦 CUSTOM DISTRIBUTION (custom_distribution field):")
    custom_dist = tournament.get('custom_distribution')
    if custom_dist:
        print(f"  Type: {type(custom_dist)}")
        if isinstance(custom_dist, list):
            print(f"  Length: {len(custom_dist)}")
            for i, prize in enumerate(custom_dist, 1):
                if isinstance(prize, dict):
                    cash = prize.get('cashAmount', 0)
                    pct = prize.get('percentage', 0)
                    print(f"  {i}. Cash: {cash:,} VND, Percentage: {pct}%")
        else:
            print(f"  Raw value: {custom_dist}")
    else:
        print("  None")
    
    print(f"\n🔧 OTHER FIELDS:")
    print(f"  prize_source: {tournament.get('prize_source')}")
    print(f"  distribution_template: {tournament.get('distribution_template')}")
    print(f"  organizer_fee_percent: {tournament.get('organizer_fee_percent')}%")
    print(f"  sponsor_contribution: {tournament.get('sponsor_contribution', 0):,} VND")

print(f"\n{'='*80}")
print("✅ Check complete")
