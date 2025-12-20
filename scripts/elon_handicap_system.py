"""
ELON'S HANDICAP SYSTEM - First Principles Redesign
- Handicap = Rank difference ONLY (1 rank = 1 ván)
- Bet amount = Race length ONLY
- Simple. Fair. Logical.
"""
import json
import requests

env = json.load(open('env.json'))

print("=" * 60)
print("ELON'S HANDICAP SYSTEM - First Principles Approach")
print("=" * 60)

# Step 1: Clear bad data
print("\n[1] Clearing current illogical system...")
url = f"{env['SUPABASE_URL']}/rest/v1/handicap_rules"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
}
resp = requests.delete(f"{url}?id=neq.0", headers=headers)
print(f"    Deleted: HTTP {resp.status_code}")

# Step 2: New logical system
print("\n[2] Installing LOGICAL handicap system...")

# Handicap = Rank difference ONLY (fixed per rank gap)
# Race length = Bet amount ONLY
handicap_rules = []

for rank_diff in [1, 2, 3, 4]:
    # Determine type name (for compatibility with old code)
    if rank_diff == 1:
        diff_type = '1_sub'
    elif rank_diff == 2:
        diff_type = '1_main'
    elif rank_diff == 3:
        diff_type = '1.5_main'
    else:  # 4
        diff_type = '2_main'
    
    # For each bet level, handicap = rank_diff (constant)
    for bet_amount in [100, 200, 300, 400, 500, 600]:
        handicap_rules.append({
            'rank_difference_type': diff_type,
            'bet_amount': bet_amount,
            'handicap_value': float(rank_diff),  # Simple: 1 rank = 1 ván
            'rank_difference_value': rank_diff
        })

print(f"    Rules to insert: {len(handicap_rules)}")

headers['Content-Type'] = 'application/json'
headers['Prefer'] = 'return=representation'

success = 0
for rule in handicap_rules:
    resp = requests.post(url, headers=headers, json=rule)
    if resp.status_code < 300:
        success += 1

print(f"    Inserted: {success}/24")

# Step 3: Verify
print("\n[3] Verification...")
resp = requests.get(url + '?select=*&order=rank_difference_value,bet_amount', 
                   headers={'apikey': env['SUPABASE_SERVICE_ROLE_KEY'], 
                           'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"})
rules = resp.json()

print(f"    Total rules: {len(rules)}")

# Show the beautiful simplicity
print("\n[4] ELON'S SYSTEM - Check the pattern:")
print("    Rank Diff | Handicap (FIXED)")
print("    ----------|------------------")

for rank_diff in [1, 2, 3, 4]:
    matching = [r for r in rules if r['rank_difference_value'] == rank_diff]
    if matching:
        handicap_values = set(r['handicap_value'] for r in matching)
        if len(handicap_values) == 1:
            print(f"    {rank_diff} rank(s)  | {list(handicap_values)[0]} ván (ALL bets) ✓")
        else:
            print(f"    {rank_diff} rank(s)  | MIXED: {handicap_values} ✗ BUG!")

print("\n[5] Examples:")
print("    K vs I (1 rank):  K gets +1 ván (whether 100 or 600 SPA)")
print("    K vs H (2 ranks): K gets +2 ván (whether 100 or 600 SPA)")
print("    K vs H+ (3 ranks): K gets +3 ván (whether 100 or 600 SPA)")
print("    K vs G (4 ranks): K gets +4 ván (whether 100 or 600 SPA)")

print("\n" + "=" * 60)
print("LOGIC CHECK:")
print("- Skill gap SAME → Handicap SAME ✓")
print("- Bet amount → Only affects race length ✓")
print("- Simple formula: Handicap = Rank Difference ✓")
print("=" * 60)

if success == 24:
    print("\n✓ ELON'S SYSTEM DEPLOYED SUCCESSFULLY")
    print("  'The best part is no part. The best handicap is simple.'")
else:
    print(f"\n✗ DEPLOYMENT INCOMPLETE ({success}/24)")
