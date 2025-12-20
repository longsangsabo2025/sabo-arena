"""
Final fix: Correct ALL ELO ranges + Populate handicap_rules
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

def api_post(env, endpoint, data):
    url = f"{env['SUPABASE_URL']}/rest/v1/{endpoint}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    return requests.post(url, headers=headers, json=data)

def api_get(env, endpoint):
    url = f"{env['SUPABASE_URL']}/rest/v1/{endpoint}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}"
    }
    return requests.get(url, headers=headers)

def main():
    print("[FINAL FIX] Correcting ELO ranges + Handicap rules")
    print("=" * 60)
    
    env = load_env()
    
    # Step 1: Fix ELO ranges (I made a mistake earlier, E and G+ conflicted)
    print("\n[1] Fixing ALL ELO ranges...")
    
    # Correct mapping after removing K+ (1100-1199) and I+ (1300-1399)
    correct_elo = [
        ('K', 1000, 1099),   # No change
        ('I', 1100, 1199),   # Was 1200-1299, moved down 100
        ('H', 1200, 1299),   # Was 1400-1499, moved down 200
        ('H+', 1300, 1399),  # Was 1500-1599, moved down 200
        ('G', 1400, 1499),   # Was 1600-1699, moved down 200
        ('G+', 1500, 1599),  # Was 1700-1799, moved down 200
        ('F', 1600, 1699),   # Was 1800-1899, moved down 200
        ('E', 1700, 1799),   # Was 1900-1999, moved down 200
        ('D', 1800, 1899),   # Was 2000-2099, moved down 200
        ('C', 1900, None),   # Was 2100-2199, moved down 200, unlimited
    ]
    
    for rank_code, elo_min, elo_max in correct_elo:
        data = {'elo_min': elo_min, 'elo_max': elo_max}
        resp = api_patch(env, f'rank_system?rank_code=eq.{rank_code}', data)
        status = '[OK]' if resp.status_code < 300 else '[ERR]'
        elo_range = f"{elo_min}-{elo_max or 'MAX'}"
        print(f"   {status} {rank_code:3s} = {elo_range}")
    
    # Step 2: Populate handicap_rules
    print("\n[2] Populating handicap_rules...")
    
    handicap_rules = [
        # 1 sub-rank difference (like K vs I, I vs H)
        {"rank_difference_type": "1_sub", "bet_amount": 5000, "handicap_points": 0.5},
        {"rank_difference_type": "1_sub", "bet_amount": 10000, "handicap_points": 0.5},
        {"rank_difference_type": "1_sub", "bet_amount": 20000, "handicap_points": 1.0},
        {"rank_difference_type": "1_sub", "bet_amount": 50000, "handicap_points": 1.0},
        {"rank_difference_type": "1_sub", "bet_amount": 100000, "handicap_points": 1.5},
        {"rank_difference_type": "1_sub", "bet_amount": 200000, "handicap_points": 1.5},
        
        # 1 main rank (like K vs H, I vs H+)
        {"rank_difference_type": "1_main", "bet_amount": 5000, "handicap_points": 1.0},
        {"rank_difference_type": "1_main", "bet_amount": 10000, "handicap_points": 1.0},
        {"rank_difference_type": "1_main", "bet_amount": 20000, "handicap_points": 1.5},
        {"rank_difference_type": "1_main", "bet_amount": 50000, "handicap_points": 2.0},
        {"rank_difference_type": "1_main", "bet_amount": 100000, "handicap_points": 2.5},
        {"rank_difference_type": "1_main", "bet_amount": 200000, "handicap_points": 3.0},
        
        # 1.5 main rank
        {"rank_difference_type": "1.5_main", "bet_amount": 5000, "handicap_points": 1.5},
        {"rank_difference_type": "1.5_main", "bet_amount": 10000, "handicap_points": 2.0},
        {"rank_difference_type": "1.5_main", "bet_amount": 20000, "handicap_points": 2.5},
        {"rank_difference_type": "1.5_main", "bet_amount": 50000, "handicap_points": 3.0},
        {"rank_difference_type": "1.5_main", "bet_amount": 100000, "handicap_points": 3.5},
        {"rank_difference_type": "1.5_main", "bet_amount": 200000, "handicap_points": 4.0},
        
        # 2 main ranks
        {"rank_difference_type": "2_main", "bet_amount": 5000, "handicap_points": 2.0},
        {"rank_difference_type": "2_main", "bet_amount": 10000, "handicap_points": 2.5},
        {"rank_difference_type": "2_main", "bet_amount": 20000, "handicap_points": 3.0},
        {"rank_difference_type": "2_main", "bet_amount": 50000, "handicap_points": 4.0},
        {"rank_difference_type": "2_main", "bet_amount": 100000, "handicap_points": 4.5},
        {"rank_difference_type": "2_main", "bet_amount": 200000, "handicap_points": 5.0},
    ]
    
    success = 0
    for rule in handicap_rules:
        resp = api_post(env, 'handicap_rules', rule)
        if resp.status_code < 300:
            success += 1
    
    print(f"   [OK] Inserted {success}/24 rules")
    
    # Verify
    print("\n[3] Verification...")
    resp = api_get(env, 'rank_system?select=rank_code,elo_min,elo_max&order=elo_min.asc')
    ranks = resp.json()
    
    print("   Ranks:")
    for r in ranks:
        elo_max = r.get('elo_max') or 'MAX'
        print(f"     {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
    
    resp = api_get(env, 'handicap_rules?select=*')
    handicap_count = len(resp.json())
    print(f"\n   Handicap rules: {handicap_count}")
    
    print("\n" + "=" * 60)
    if len(ranks) == 10 and handicap_count >= 24:
        print("[SUCCESS] Migration complete!")
        print("  - K+ and I+ removed")
        print("  - 10 ranks with shifted ELO ranges")
        print("  - Handicap rules populated")
    else:
        print(f"[WARNING] Expected 10 ranks & 24 rules, got {len(ranks)} & {handicap_count}")

if __name__ == '__main__':
    main()
