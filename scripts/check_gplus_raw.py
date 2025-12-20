import json, requests
e=json.load(open('env.json'))
r=requests.get(f'{e["SUPABASE_URL"]}/rest/v1/rank_system?rank_code=eq.G%2B',headers={'apikey':e['SUPABASE_SERVICE_ROLE_KEY'],'Authorization':f'Bearer {e["SUPABASE_SERVICE_ROLE_KEY"]}'})
print("G+ raw:")
import pprint
pprint.pprint(r.json())
