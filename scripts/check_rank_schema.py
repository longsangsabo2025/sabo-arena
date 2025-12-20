import json
import requests

env = json.load(open('env.json'))

url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?select=*&limit=1"
headers = {
    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
}

resp = requests.get(url, headers=headers)
data = resp.json()

if data:
    print("📋 RANK_SYSTEM SCHEMA:")
    print("Available columns:")
    for key in data[0].keys():
        print(f"  - {key}")
