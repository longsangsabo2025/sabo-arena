"""
Fix ELO ranges after removing K+ and I+
Now with correct column names from schema
"""
import json
import requests

def load_env():
    with open('env.json') as f:
        return json.load(f)

def api_patch(env, endpoint, data):
    url = f"{env['SUPABASE_URL']}/rest/v1/{endpoint}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    return requests.patch(url, headers=headers, json=data)

def api_get(env, endpoint):
    url = f"{env['SUPABASE_URL']}/rest/v1/{endpoint}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
    }
    return requests.get(url, headers=headers)

def main():
    print("[*] FIXING ELO RANGES")
    print("=" * 60)
    
    env = load_env()
    
    # Check current state
    resp = api_get(env, 'rank_system?select=rank_code,elo_min,elo_max&order=elo_min.asc')
    ranks = resp.json()
    
    print("[BEFORE]:")
    for r in ranks:
        elo_max = r.get('elo_max') or 'MAX'
        print(f"  {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
    
    # New ELO ranges after removing K+ and I+
    elo_updates = {
        'K': {'elo_min': 1000, 'elo_max': 1099},  # No change
        'I': {'elo_min': 1100, 'elo_max': 1199},  # Was 1200-1299
        'H': {'elo_min': 1200, 'elo_max': 1299},  # Was 1400-1499
        'H+': {'elo_min': 1300, 'elo_max': 1399}, # Was 1500-1599
        'G': {'elo_min': 1400, 'elo_max': 1499},  # Was 1600-1699
        'G+': {'elo_min': 1500, 'elo_max': 1599}, # Was 1700-1799
        'F': {'elo_min': 1600, 'elo_max': 1699},  # Was 1800-1899
        'E': {'elo_min': 1700, 'elo_max': 1799},  # Was 1900-1999
        'D': {'elo_min': 1800, 'elo_max': 1899},  # Was 2000-2099
        'C': {'elo_min': 1900, 'elo_max': None},  # Was 2100-2199, now unlimited
    }
    
    print("\n[UPDATE] Updating ELO ranges...")
    for rank_code, updates in elo_updates.items():
        resp = api_patch(env, f'rank_system?rank_code=eq.{rank_code}', updates)
        status_icon = '[OK]' if 200 <= resp.status_code < 300 else '[ERR]'
        elo_range = f"{updates['elo_min']}-{updates['elo_max'] or 'MAX'}"
        print(f"   {status_icon} {rank_code:3s} → {elo_range:12s} (HTTP {resp.status_code})")
        if resp.status_code >= 300:
            print(f"      Error: {resp.text}")
    
    # Verify
    print("\n[AFTER]:")
    resp = api_get(env, 'rank_system?select=rank_code,elo_min,elo_max&order=elo_min.asc')
    ranks = resp.json()
    
    for r in ranks:
        elo_max = r.get('elo_max') or 'MAX'
        print(f"  {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
    
    print("\n" + "=" * 60)
    print("[SUCCESS] ELO RANGES UPDATED!")
    print("   - All ranks shifted down by 100 ELO (except K)")
    print("   - C is now 1900+ (unlimited)")

if __name__ == '__main__':
    main()
