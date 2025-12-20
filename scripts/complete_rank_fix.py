"""
Complete fix: ELO ranges + rank_order
After removing K+ and I+, we need continuous rank_order 1-10
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
    print("[COMPLETE FIX] ELO ranges + rank_order")
    print("=" * 60)
    
    env = load_env()
    
    # Define correct rank system after removing K+ (order 2) and I+ (order 4)
    # rank_code, rank_order, elo_min, elo_max
    correct_ranks = [
        ('K', 1, 1000, 1099),   # Was order 1, keep same ELO
        ('I', 2, 1100, 1199),   # Was order 3, now 2 (shift ELO down from 1200)
        ('H', 3, 1200, 1299),   # Was order 5, now 3 (shift ELO down from 1400)
        ('H+', 4, 1300, 1399),  # Was order 6, now 4 (shift ELO down from 1500)
        ('G', 5, 1400, 1499),   # Was order 7, now 5 (shift ELO down from 1600)
        ('G+', 6, 1500, 1599),  # Was order 8, now 6 (shift ELO down from 1700)
        ('F', 7, 1600, 1699),   # Was order 9, now 7 (shift ELO down from 1800)
        ('E', 8, 1700, 1799),   # Was order 10, now 8 (shift ELO down from 1900)
        ('D', 9, 1800, 1899),   # Was order 11, now 9 (shift ELO down from 2000)
        ('C', 10, 1900, None),  # Was order 12, now 10 (shift ELO down from 2100, unlimited)
    ]
    
    print("[UPDATE] Setting rank_order + ELO...")
    for rank_code, order, elo_min, elo_max in correct_ranks:
        data = {
            'rank_order': order,
            'elo_min': elo_min,
            'elo_max': elo_max
        }
        resp = api_patch(env, f'rank_system?rank_code=eq.{rank_code}', data)
        status = '[OK]' if resp.status_code < 300 else '[ERR]'
        elo_range = f"{elo_min}-{elo_max or 'MAX'}"
        print(f"   {status} {order:2}. {rank_code:3s} = {elo_range}")
        if resp.status_code >= 300:
            print(f"       Error: {resp.text}")
    
    # Verify
    print("\n[VERIFY] Final rank system:")
    resp = api_get(env, 'rank_system?select=rank_code,rank_order,elo_min,elo_max&order=rank_order.asc')
    ranks = resp.json()
    
    for r in ranks:
        elo_max = r.get('elo_max') or 'MAX'
        print(f"   {r['rank_order']:2}. {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
    
    print("\n" + "=" * 60)
    print("[SUCCESS] Migration COMPLETE!")
    print("  - 10 ranks: K, I, H, H+, G, G+, F, E, D, C")
    print("  - ELO shifted down by 100-200 points")
    print("  - rank_order 1-10 (continuous)")

if __name__ == '__main__':
    main()
