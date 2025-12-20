import json
import requests

env = json.load(open('env.json'))

# Try updating H+
url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.H%2B"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

data = {'rank_order': 4, 'elo_min': 1300, 'elo_max': 1399}

print(f"Updating H+ to: {data}")
resp = requests.patch(url, headers=headers, json=data)
print(f"Status: {resp.status_code}")
print(f"Response: {resp.text}")

# Verify
url2 = f"{env['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.H%2B&select=rank_code,rank_order,elo_min,elo_max"
resp2 = requests.get(url2, headers={'apikey': env['SUPABASE_SERVICE_ROLE_KEY'], 'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"})
print(f"\nAfter update: {resp2.json()}")
