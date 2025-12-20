#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Verify all handicap_rules values for race to 7 system"""

import os
import sys
from pathlib import Path
import requests
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

SUPABASE_URL = os.getenv('SUPABASE_URL')
SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

print("=" * 60)
print("HANDICAP RULES - RACE TO 7 VERIFICATION")
print("=" * 60)

# Get all handicap rules
url = f"{SUPABASE_URL}/rest/v1/handicap_rules"
params = {'select': '*', 'order': 'rank_difference_type.asc,bet_amount.asc'}

response = requests.get(url, headers=headers, params=params)
if response.status_code == 200:
    rules = response.json()
    print(f"\n✓ Found {len(rules)} handicap rules\n")
    
    # Display all rules
    print(f"{'Type':<15} {'Bet':<8} {'Handicap':<10} {'Rank Diff'}")
    print("-" * 50)
    for rule in rules:
        print(f"{rule['rank_difference_type']:<15} "
              f"{rule.get('bet_amount', 'N/A'):<8} "
              f"{rule.get('handicap_value', 'N/A'):<10} "
              f"{rule.get('rank_difference_value', 'N/A')}")
    
    # For race to 7 system, handicap should be simple:
    # - Based on rank difference only
    # - Not related to bet_amount (that's for challenge system)
    print("\n" + "=" * 60)
    print("RACE TO 7 HANDICAP LOGIC:")
    print("=" * 60)
    print("• 1 sub-rank difference  → 0.5 ván handicap")
    print("• 1 main rank difference → 1.0 ván handicap")
    print("• 1.5 main rank diff     → 1.5 ván handicap")
    print("• 2 main ranks diff      → 2.0 ván handicap")
    print("\nbet_amount should NOT affect handicap for race to 7")
    print("bet_amount is for challenge/betting system (separate feature)")
    
else:
    print(f"✗ Failed to fetch rules: {response.status_code}")
    print(response.text)
