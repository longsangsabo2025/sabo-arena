import json, requests, time
env = json.load(open('env.json'))

def update(rank_code, order, elo_min, elo_max):
    url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.{rank_code}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    data = {'rank_order': order, 'elo_min': elo_min, 'elo_max': elo_max}
    resp = requests.patch(url, headers=headers, json=data)
    print(f"{rank_code} -> order={order}, ELO={elo_min}-{elo_max or 'MAX'}: HTTP {resp.status_code}")
    return resp.status_code == 200

# Update G+ to order 6
update('G+', 6, 1500, 1599)
time.sleep(0.5)

# Verify all
url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?select=rank_code,rank_order,elo_min,elo_max&order=rank_order.asc"
resp = requests.get(url, headers={'apikey': env['SUPABASE_SERVICE_ROLE_KEY'], 'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"})

print("\nFinal state:")
for r in resp.json():
    elo_max = r.get('elo_max') or 'MAX'
    print(f"  {r['rank_order']:2}. {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
