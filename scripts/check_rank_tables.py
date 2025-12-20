import json
from supabase import create_client

# Load env
with open('env.json') as f:
    env = json.load(f)

# Use ANON key (service key might not be in env.json)
supabase = create_client(env['SUPABASE_URL'], env['SUPABASE_ANON_KEY'])

print('=== RANK_SYSTEM TABLE ===')
try:
    result = supabase.table('rank_system').select('*').order('elo_min').execute()
    if result.data:
        print(f"Found {len(result.data)} ranks:")
        for row in result.data:
            elo_max = row.get('elo_max') if row.get('elo_max') else 'MAX'
            print(f"  {row.get('rank_code')} | ELO: {row.get('elo_min')}-{elo_max} | Display: {row.get('display_name')}")
    else:
        print('Table exists but EMPTY - needs population!')
except Exception as e:
    print(f'Error: {e}')

print('\n=== HANDICAP_RULES TABLE ===')
try:
    result = supabase.table('handicap_rules').select('*').limit(10).execute()
    if result.data:
        print(f"Found {len(result.data)} handicap rules:")
        for row in result.data[:5]:
            print(f"  ID: {row.get('id')} | Rank diff: {row.get('rank_difference')} | Handicap: {row.get('handicap_value')}")
    else:
        print('Table exists but EMPTY - needs population!')
except Exception as e:
    print(f'Error: {e}')
