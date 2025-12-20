import json
import requests

env = json.load(open('env.json'))

url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?rank_code=eq.H%2B&select=*"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
}

resp = requests.get(url, headers=headers)
print("H+ data:")
import pprint
pprint.pprint(resp.json())
