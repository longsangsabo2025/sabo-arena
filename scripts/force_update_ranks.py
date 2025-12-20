"""
Force update each rank individually with delays
"""
import json
import requests
import time

env = json.load(open('env.json'))

def update_rank(rank_code, order, elo_min, elo_max):
    url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.{rank_code}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    data = {'rank_order': order, 'elo_min': elo_min, 'elo_max': elo_max}
    resp = requests.patch(url, headers=headers, json=data)
    return resp.status_code

ranks = [
    ('K', 1, 1000, 1099),
    ('I', 2, 1100, 1199),
    ('H', 3, 1200, 1299),
    ('H+', 4, 1300, 1399),
    ('G', 5, 1400, 1499),
    ('G+', 6, 1500, 1599),
    ('F', 7, 1600, 1699),
    ('E', 8, 1700, 1799),
    ('D', 9, 1800, 1899),
    ('C', 10, 1900, None),
]

print("Updating ranks...")
for rank_code, order, elo_min, elo_max in ranks:
    status = update_rank(rank_code, order, elo_min, elo_max)
    elo_range = f"{elo_min}-{elo_max or 'MAX'}"
    print(f"  {rank_code:3s} order={order:2} ELO={elo_range:12s} -> HTTP {status}")
    time.sleep(0.2)  # Small delay

# Verify
print("\nVerifying...")
url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?select=rank_code,rank_order,elo_min,elo_max&order=rank_order.asc"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
}
resp = requests.get(url, headers=headers)
ranks = resp.json()

for r in ranks:
    elo_max = r.get('elo_max') or 'MAX'
    print(f"  {r['rank_order']:2}. {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
