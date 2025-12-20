import json, requests, time
e=json.load(open('env.json'))

print("BEFORE G+ update:")
r=requests.get(f"{e['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.G%2B",headers={'apikey':e['SUPABASE_SERVICE_ROLE_KEY'],'Authorization':f"Bearer {e['SUPABASE_SERVICE_ROLE_KEY']}"})
gplus_before = r.json()[0]
print(f"  order={gplus_before['rank_order']}, elo={gplus_before['elo_min']}-{gplus_before['elo_max']}")

print("\nSending UPDATE request...")
data = {'rank_order': 6, 'elo_min': 1500, 'elo_max': 1599}
print(f"  Data: {data}")
resp = requests.patch(
    f"{e['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.G%2B",
    headers={
        'apikey': e['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {e['SUPABASE_SERVICE_ROLE_KEY']}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    },
    json=data
)
print(f"  Status: {resp.status_code}")
print(f"  Response body: {resp.text}")

time.sleep(1)

print("\nAFTER G+ update (with cache bypass):")
r=requests.get(f"{e['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.G%2B&cachebust={time.time()}",headers={'apikey':e['SUPABASE_SERVICE_ROLE_KEY'],'Authorization':f"Bearer {e['SUPABASE_SERVICE_ROLE_KEY']}"})
gplus_after = r.json()[0]
print(f"  order={gplus_after['rank_order']}, elo={gplus_after['elo_min']}-{gplus_after['elo_max']}")

if gplus_after['rank_order'] == 6 and gplus_after['elo_min'] == 1500:
    print("\n✓ UPDATE SUCCESSFUL!")
else:
    print("\n✗ UPDATE FAILED - values unchanged")
