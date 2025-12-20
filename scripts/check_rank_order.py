import json
import requests

env = json.load(open('env.json'))

url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?select=*&order=rank_order.asc"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
}

resp = requests.get(url, headers=headers)
ranks = resp.json()

print("RANK_SYSTEM (ordered by rank_order):")
for r in ranks:
    elo_max = r.get('elo_max') or 'MAX'
    print(f"  Order {r.get('rank_order', '?'):2} | {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
