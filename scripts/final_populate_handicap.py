"""
Populate handicap_rules with CORRECT values from ChallengeRulesService
Schema: rank_difference_type, bet_amount, handicap_value, rank_difference_value
"""
import json
import requests

env = json.load(open('env.json'))

# Clear existing data
print("[1] Clearing existing handicap_rules...")
url = f"{env['SUPABASE_URL']}/rest/v1/handicap_rules"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
}
resp = requests.delete(f"{url}?id=neq.0", headers=headers)
print(f"    Deleted: HTTP {resp.status_code}")

# Handicap Matrix from ChallengeRulesService.dart
handicap_data = [
    # 1_sub (chênh 1 rank: K vs I, H vs H+)
    {'rank_difference_type': '1_sub', 'bet_amount': 100, 'handicap_value': 0.5, 'rank_difference_value': 1},
    {'rank_difference_type': '1_sub', 'bet_amount': 200, 'handicap_value': 1.0, 'rank_difference_value': 1},
    {'rank_difference_type': '1_sub', 'bet_amount': 300, 'handicap_value': 1.5, 'rank_difference_value': 1},
    {'rank_difference_type': '1_sub', 'bet_amount': 400, 'handicap_value': 1.5, 'rank_difference_value': 1},
    {'rank_difference_type': '1_sub', 'bet_amount': 500, 'handicap_value': 2.0, 'rank_difference_value': 1},
    {'rank_difference_type': '1_sub', 'bet_amount': 600, 'handicap_value': 2.5, 'rank_difference_value': 1},
    
    # 1_main (chênh 2 ranks: K vs H, I vs G)
    {'rank_difference_type': '1_main', 'bet_amount': 100, 'handicap_value': 1.0, 'rank_difference_value': 2},
    {'rank_difference_type': '1_main', 'bet_amount': 200, 'handicap_value': 1.5, 'rank_difference_value': 2},
    {'rank_difference_type': '1_main', 'bet_amount': 300, 'handicap_value': 2.0, 'rank_difference_value': 2},
    {'rank_difference_type': '1_main', 'bet_amount': 400, 'handicap_value': 2.5, 'rank_difference_value': 2},
    {'rank_difference_type': '1_main', 'bet_amount': 500, 'handicap_value': 3.0, 'rank_difference_value': 2},
    {'rank_difference_type': '1_main', 'bet_amount': 600, 'handicap_value': 3.5, 'rank_difference_value': 2},
    
    # 1.5_main (chênh 3 ranks: K vs H+, I vs G+)
    {'rank_difference_type': '1.5_main', 'bet_amount': 100, 'handicap_value': 1.5, 'rank_difference_value': 3},
    {'rank_difference_type': '1.5_main', 'bet_amount': 200, 'handicap_value': 2.5, 'rank_difference_value': 3},
    {'rank_difference_type': '1.5_main', 'bet_amount': 300, 'handicap_value': 3.5, 'rank_difference_value': 3},
    {'rank_difference_type': '1.5_main', 'bet_amount': 400, 'handicap_value': 4.0, 'rank_difference_value': 3},
    {'rank_difference_type': '1.5_main', 'bet_amount': 500, 'handicap_value': 5.0, 'rank_difference_value': 3},
    {'rank_difference_type': '1.5_main', 'bet_amount': 600, 'handicap_value': 6.0, 'rank_difference_value': 3},
    
    # 2_main (chênh 4 ranks: K vs G, I vs G+)
    {'rank_difference_type': '2_main', 'bet_amount': 100, 'handicap_value': 2.0, 'rank_difference_value': 4},
    {'rank_difference_type': '2_main', 'bet_amount': 200, 'handicap_value': 3.0, 'rank_difference_value': 4},
    {'rank_difference_type': '2_main', 'bet_amount': 300, 'handicap_value': 4.0, 'rank_difference_value': 4},
    {'rank_difference_type': '2_main', 'bet_amount': 400, 'handicap_value': 5.0, 'rank_difference_value': 4},
    {'rank_difference_type': '2_main', 'bet_amount': 500, 'handicap_value': 6.0, 'rank_difference_value': 4},
    {'rank_difference_type': '2_main', 'bet_amount': 600, 'handicap_value': 7.0, 'rank_difference_value': 4},
]

print(f"\n[2] Inserting {len(handicap_data)} rules...")
headers['Content-Type'] = 'application/json'
headers['Prefer'] = 'return=representation'

success = 0
for rule in handicap_data:
    resp = requests.post(url, headers=headers, json=rule)
    if resp.status_code < 300:
        success += 1
        print(f"    [OK] {rule['rank_difference_type']:8s} / {rule['bet_amount']:3d} SPA = {rule['handicap_value']} handicap")
    else:
        print(f"    [ERR] {rule['rank_difference_type']} / {rule['bet_amount']}: {resp.status_code}")

print(f"\n[3] Verification...")
resp = requests.get(url + '?select=*', headers={'apikey': env['SUPABASE_SERVICE_ROLE_KEY'], 'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"})
rules = resp.json()

print(f"    Total rules: {len(rules)}")
print(f"    Success: {success}/24")

if len(rules) == 24:
    print("\n[SUCCESS] All 24 handicap rules populated!")
    
    # Show sample
    print("\nSample rules:")
    for r in rules[:3]:
        print(f"  {r['rank_difference_type']:8s} | {r['bet_amount']:3d} SPA | handicap={r['handicap_value']}")
else:
    print(f"\n[WARNING] Expected 24 rules, got {len(rules)}")
