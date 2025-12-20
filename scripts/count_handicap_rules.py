import json, requests
e=json.load(open('env.json'))

print("Checking handicap_rules...")
r=requests.get(
    f"{e['SUPABASE_URL']}/rest/v1/handicap_rules?select=*",
    headers={
        'apikey': e['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {e['SUPABASE_SERVICE_ROLE_KEY']}"
    }
)

rules = r.json()
print(f"Total rules: {len(rules)}")

if len(rules) > 0:
    print("\nSample rules (first 5):")
    for rule in rules[:5]:
        print(f"  Type: {rule.get('rank_difference_type')} | Bet: {rule.get('bet_amount')} | Handicap: {rule.get('handicap_points')}")
else:
    print("\nTable is EMPTY!")
