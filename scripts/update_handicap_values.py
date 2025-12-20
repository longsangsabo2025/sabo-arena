"""
Update existing handicap_rules with correct handicap_value
"""
import json
import requests

env = json.load(open('env.json'))

# Handicap Matrix from ChallengeRulesService
updates = [
    # 1_sub
    ('1_sub', 100, 0.5, 1), ('1_sub', 200, 1.0, 1), ('1_sub', 300, 1.5, 1),
    ('1_sub', 400, 1.5, 1), ('1_sub', 500, 2.0, 1), ('1_sub', 600, 2.5, 1),
    # 1_main
    ('1_main', 100, 1.0, 2), ('1_main', 200, 1.5, 2), ('1_main', 300, 2.0, 2),
    ('1_main', 400, 2.5, 2), ('1_main', 500, 3.0, 2), ('1_main', 600, 3.5, 2),
    # 1.5_main
    ('1.5_main', 100, 1.5, 3), ('1.5_main', 200, 2.5, 3), ('1.5_main', 300, 3.5, 3),
    ('1.5_main', 400, 4.0, 3), ('1.5_main', 500, 5.0, 3), ('1.5_main', 600, 6.0, 3),
    # 2_main
    ('2_main', 100, 2.0, 4), ('2_main', 200, 3.0, 4), ('2_main', 300, 4.0, 4),
    ('2_main', 400, 5.0, 4), ('2_main', 500, 6.0, 4), ('2_main', 600, 7.0, 4),
]

print("[UPDATE] Setting handicap_value for 24 rules...")

url = f"{env['SUPABASE_URL']}/rest/v1/handicap_rules"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

success = 0
for rank_diff_type, bet, handicap, rank_diff_val in updates:
    # Update where rank_difference_type and bet_amount match
    query = f"{url}?rank_difference_type=eq.{rank_diff_type}&bet_amount=eq.{bet}"
    data = {
        'handicap_value': handicap,
        'rank_difference_value': rank_diff_val
    }
    resp = requests.patch(query, headers=headers, json=data)
    
    if resp.status_code < 300:
        success += 1
        print(f"  [OK] {rank_diff_type:8s} / {bet:3d} SPA -> {handicap}")
    else:
        print(f"  [ERR] {rank_diff_type} / {bet}: HTTP {resp.status_code}")

print(f"\n[VERIFY] Checking results...")
resp = requests.get(url + '?select=*&order=rank_difference_type,bet_amount', 
                   headers={'apikey': env['SUPABASE_SERVICE_ROLE_KEY'], 
                           'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"})
rules = resp.json()

print(f"  Total: {len(rules)} rules")
print(f"  Updated: {success}/24")

# Check if any null
null_count = sum(1 for r in rules if r.get('handicap_value') is None)
print(f"  Null handicap_value: {null_count}")

if null_count == 0:
    print("\n[SUCCESS] All handicap values populated!")
    print("\nSample (first 6):")
    for r in rules[:6]:
        print(f"  {r['rank_difference_type']:8s} | {r['bet_amount']:3d} SPA | handicap={r['handicap_value']}")
else:
    print(f"\n[WARNING] {null_count} rules still have NULL handicap_value")
