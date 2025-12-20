#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Implement basic race to 7 handicap - Elon mode: simple and fast"""

import os
import sys
from pathlib import Path
import requests
from dotenv import load_dotenv

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

SUPABASE_URL = os.getenv('SUPABASE_URL')
SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
}

print("=" * 60)
print("IMPLEMENTING BASIC RACE TO 7 HANDICAP")
print("=" * 60)

# Step 1: Delete ALL existing rules
print("\n1️⃣ Clearing existing handicap_rules...")
delete_url = f"{SUPABASE_URL}/rest/v1/handicap_rules"
response = requests.delete(delete_url, headers=headers, params={'id': 'not.is.null'})
print(f"   DELETE: HTTP {response.status_code}")

# Step 2: Insert 10 simple rules (rank_diff 0-9)
print("\n2️⃣ Inserting basic handicap rules...")

ranks = ['K', 'I', 'H', 'H+', 'G', 'G+', 'F', 'E', 'D', 'C']
rules = []

for i in range(10):
    for j in range(10):
        diff = abs(i - j)
        if diff > 0:  # Only create rules for actual differences
            rules.append({
                'rank_difference_type': f'{diff}_rank',
                'rank_difference_value': diff,
                'handicap_value': float(diff),
                'bet_amount': None,  # NULL for basic handicap
                'description': f'{ranks[min(i,j)]} vs {ranks[max(i,j)]}: {diff} ván handicap'
            })

# Remove duplicates by using unique diff values
unique_rules = []
seen_diffs = set()
for rule in rules:
    diff = rule['rank_difference_value']
    if diff not in seen_diffs:
        unique_rules.append({
            'rank_difference_type': f'{diff}_rank',
            'rank_difference_value': diff,
            'handicap_value': float(diff),
            'bet_amount': None,
            'description': f'Rank difference {diff}: {diff} ván handicap'
        })
        seen_diffs.add(diff)

print(f"   Creating {len(unique_rules)} basic rules...")

insert_url = f"{SUPABASE_URL}/rest/v1/handicap_rules"
for rule in unique_rules:
    response = requests.post(insert_url, headers=headers, json=rule)
    status = '✅' if response.status_code in [200, 201] else '❌'
    print(f"   {status} Rank diff {rule['rank_difference_value']}: handicap={rule['handicap_value']} → HTTP {response.status_code}")

# Step 3: Verify
print("\n3️⃣ Verifying...")
verify_url = f"{SUPABASE_URL}/rest/v1/handicap_rules"
params = {'select': '*', 'order': 'rank_difference_value.asc'}
response = requests.get(verify_url, headers=headers, params=params)

if response.status_code == 200:
    rules = response.json()
    print(f"✅ Total rules: {len(rules)}\n")
    
    print(f"{'Rank Diff':<12} {'Handicap':<10} {'Description'}")
    print("-" * 50)
    for rule in rules:
        print(f"{rule['rank_difference_value']:<12} "
              f"{rule['handicap_value']:<10} "
              f"{rule.get('description', 'N/A')}")

print("\n" + "=" * 60)
print("✅ BASIC HANDICAP IMPLEMENTATION COMPLETE")
print("=" * 60)
print("\nLogic: rank_difference = handicap_value (1:1 mapping)")
print("Example: K(1) vs H(3) = diff 2 → 2 ván handicap")
print("Race to: Always 7 for basic matches")
