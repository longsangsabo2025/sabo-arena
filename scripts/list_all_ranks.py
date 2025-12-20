import json, requests
e=json.load(open('env.json'))
print('All ranks (by ELO):')
r=requests.get(f"{e['SUPABASE_URL']}/rest/v1/rank_system?select=rank_code,rank_order,elo_min,elo_max&order=elo_min.asc",headers={'apikey':e['SUPABASE_SERVICE_ROLE_KEY'],'Authorization':f"Bearer {e['SUPABASE_SERVICE_ROLE_KEY']}"})
for x in r.json():
    print(f"  {x['rank_code']:3s} order={x['rank_order']:2} elo={x['elo_min']}-{x.get('elo_max') or 'MAX'}")
