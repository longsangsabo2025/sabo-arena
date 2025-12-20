#!/usr/bin/env python3
"""Check handicap_rules table schema"""

import os
import sys
from pathlib import Path
import requests
from dotenv import load_dotenv

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

SUPABASE_URL = os.getenv('SUPABASE_URL')
SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

# Get schema via RPC or direct query
headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

# Try to insert ONE rule with all possible fields to see error
test_rule = {
    'rank_difference_type': '1_rank',
    'rank_difference_value': 1,
    'handicap_value': 1.0,
    'bet_amount': None,
    'description': 'Test'
}

url = f"{SUPABASE_URL}/rest/v1/handicap_rules"
response = requests.post(url, headers=headers, json=test_rule)

print(f"Status: {response.status_code}")
print(f"Response: {response.text}")

# If failed, try with required fields only
if response.status_code != 201:
    print("\nTrying minimal fields...")
    minimal = {
        'rank_difference_type': '1_rank',
        'handicap_value': 1.0
    }
    response2 = requests.post(url, headers=headers, json=minimal)
    print(f"Status: {response2.status_code}")
    print(f"Response: {response2.text}")
