"""
Direct Rank System Migration via Supabase REST API
Hardcoded operations for reliability
"""
import json
import requests

def load_env():
    with open('env.json') as f:
        return json.load(f)

def api_request(env, method, endpoint, data=None):
    """Make API request to Supabase"""
    url = f"{env['SUPABASE_URL']}/rest/v1/{endpoint}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    
    if method == 'GET':
        resp = requests.get(url, headers=headers)
    elif method == 'DELETE':
        resp = requests.delete(url, headers=headers)
    elif method == 'PATCH':
        resp = requests.patch(url, headers=headers, json=data)
    elif method == 'POST':
        resp = requests.post(url, headers=headers, json=data)
    
    return resp

def verify_ranks(env):
    """Get current rank system"""
    resp = api_request(env, 'GET', 'rank_system?select=rank_code,elo_min,elo_max&order=elo_min.asc')
    ranks = resp.json()
    
    print(f"\n📊 Ranks: {len(ranks)}")
    for r in ranks:
        elo_max = r.get('elo_max') or 'MAX'
        print(f"  {r['rank_code']:3s} | {r['elo_min']}-{elo_max}")
    
    return ranks

def main():
    print("🚀 RANK SYSTEM MIGRATION VIA REST API")
    print("=" * 60)
    
    env = load_env()
    print(f"✅ Connected to: {env['SUPABASE_URL']}")
    
    print("\n📊 BEFORE:")
    ranks_before = verify_ranks(env)
    
    if len(ranks_before) == 10:
        print("\n⚠️  Already migrated (10 ranks found)")
        return
    
    # Step 1: Delete K+ and I+
    print("\n🗑️  Step 1: Deleting K+ and I+...")
    resp = api_request(env, 'DELETE', 'rank_system?rank_code=eq.K%2B')
    print(f"   K+: {resp.status_code}")
    
    resp = api_request(env, 'DELETE', 'rank_system?rank_code=eq.I%2B')
    print(f"   I+: {resp.status_code}")
    
    # Step 2: Update remaining ranks
    print("\n✏️  Step 2: Updating rank definitions...")
    
    rank_updates = [
        # K (no change - keep 1000-1099)
        ('K', {
            'display_name': 'Kỹ Sư',
            'stability_description': 'Mới vào nghề, kiến thức lý thuyết cơ bản: hiểu về nhảy 1 băng, nhảy 2 băng, đánh xoay và hệ thống điểm của bàn bi-a. Kỹ năng kiểm soát cơ bản: Có thể đánh thẳng bi chủ, nhưng chưa điều khiển tốt lực và xoáy. Độ chính xác trung bình thấp khoảng 30-40%.'
        }),
        # I (shift from 1200-1299 to 1100-1199)
        ('I', {
            'elo_min': 1100,
            'elo_max': 1199,
            'display_name': 'Inh Ca',
            'stability_description': 'Thợ nghiệp dư với kỹ năng cơ bản ổn định: điều khiển cơ bản tốt, tư duy và lên kế hoạch còn yếu. Đánh cơ bản tốt 50-60%. Chỉ có thể nghĩ 1-2 bước trước. Nắm được xoáy phải trái nhưng chưa thành thạo các đường bi khó.'
        }),
        # H (shift from 1400-1499 to 1200-1299)
        ('H', {
            'elo_min': 1200,
            'elo_max': 1299,
            'display_name': 'H-Trần',
            'stability_description': 'Thợ trung cấp có kinh nghiệm thực tế: điều khiển tốt, có thể đọc bàn và lên kế hoạch 2-3 bước. Khả năng xử lý tình huống bi xấu, bi khó. Tỷ lệ chính xác các cú cơ bản khoảng 65-75%. Bắt đầu hiểu được kỹ thuật xoáy phức tạp.'
        }),
        # H+ (shift from 1500-1599 to 1300-1399)
        ('H+', {
            'elo_min': 1300,
            'elo_max': 1399,
            'display_name': 'H-Trần +',
            'stability_description': 'Thợ trung cấp khá. Điều khiển bi chủ rất tốt, tư duy chiến thuật sắc bén, có thể lên kế hoạch 3-4 bước. Độ chính xác đường bi cơ bản khoảng 75-80%. Kiểm soát lực đánh và xoáy tinh tế. Xử lý tình huống bi khó tốt hơn.'
        }),
        # G (shift from 1600-1699 to 1400-1499)
        ('G', {
            'elo_min': 1400,
            'elo_max': 1499,
            'display_name': 'Gò Xơ',
            'stability_description': 'Thợ bậc cao với kinh nghiệm dày dạn: điều khiển gần như hoàn hảo, tư duy chiến lược rõ ràng, có thể lên kế hoạch 4-5 bước. Độ chính xác đường bi cơ bản khoảng 80-85%. Nắm vững mọi kỹ thuật cơ bản và nâng cao. Bắt đầu thực hiện các cú đánh sáng tạo.'
        }),
        # G+ (shift from 1700-1799 to 1500-1599)
        ('G+', {
            'elo_min': 1500,
            'elo_max': 1599,
            'display_name': 'Gò Xơ +',
            'stability_description': 'Thợ bậc cao xuất sắc: điều khiển hoàn hảo, tư duy chiến lược sâu sắc, lên kế hoạch 5-6 bước. Độ chính xác 85-90%. Thực hiện được hầu hết các cú kỹ thuật phức tạp. Hiểu rõ tâm lý đối thủ và điều chỉnh lối chơi linh hoạt.'
        }),
        # F (shift from 1800-1899 to 1600-1699)
        ('F', {
            'elo_min': 1600,
            'elo_max': 1699,
            'display_name': 'Phờ',
            'stability_description': 'Tay chơi bán chuyên nghiệp: kỹ thuật gần như hoàn hảo, tư duy chiến lược xuất sắc, lên kế hoạch 6-8 bước. Độ chính xác 90-92%. Thực hiện được mọi kỹ thuật nâng cao. Khả năng đọc bàn và xử lý tình huống xuất sắc. Bắt đầu tham gia thi đấu cấp vùng.'
        }),
        # F+ (add new - was removed but needed for continuity)
        # Skip F+ since we're going 10 ranks
        
        # E (shift from 1900-1999 to 1700-1799)
        ('E', {
            'elo_min': 1700,
            'elo_max': 1799,
            'display_name': 'E',
            'stability_description': 'Tay chơi cấp cao: kỹ thuật hoàn hảo, tư duy chiến lược đỉnh cao. Độ chính xác 92-95%. Khả năng kiểm soát bi chủ tuyệt đối. Thực hiện được các cú đánh sáng tạo và đẹp mắt. Tham gia thi đấu cấp quốc gia.'
        }),
        # D (shift from 2000-2099 to 1800-1899)
        ('D', {
            'elo_min': 1800,
            'elo_max': 1899,
            'display_name': 'D',
            'stability_description': 'Tay chơi chuyên nghiệp: kỹ thuật hoàn hảo tuyệt đối, tư duy chiến lược sâu sắc và linh hoạt. Độ chính xác 95-97%. Kiểm soát hoàn toàn mọi yếu tố. Khả năng sáng tạo và biến tấu cao. Thi đấu cấp quốc tế.'
        }),
        # C (shift from 2100-2199 to 1900+)
        ('C', {
            'elo_min': 1900,
            'elo_max': None,  # No upper limit
            'display_name': 'C',
            'stability_description': 'Tay chơi đẳng cấp thế giới: kỹ thuật siêu việt, tư duy chiến lược vượt trội. Độ chính xác >97%. Kiểm soát tuyệt đối mọi yếu tố trận đấu. Khả năng sáng tạo đỉnh cao. Thi đấu và vô địch các giải quốc tế lớn. Là huyền thoại trong làng bi-a.'
        }),
    ]
    
    for rank_code, updates in rank_updates:
        resp = api_request(env, 'PATCH', f'rank_system?rank_code=eq.{rank_code}', updates)
        status_icon = '✅' if 200 <= resp.status_code < 300 else '❌'
        print(f"   {status_icon} {rank_code}: {resp.status_code}")
        if resp.status_code >= 300:
            print(f"      Error: {resp.text}")
    
    # Step 3: Verify handicap_rules (should already have 24 rules)
    print("\n🎯 Step 3: Checking handicap_rules...")
    resp = api_request(env, 'GET', 'handicap_rules?select=*')
    handicap_count = len(resp.json())
    print(f"   Current rules: {handicap_count}")
    
    if handicap_count == 0:
        print("   ⚠️  Empty! Need to populate...")
        # Add handicap rules
        handicap_data = [
            # 1 sub-rank (±1 level like K vs I)
            {"rank_difference_type": "1_sub", "bet_amount": 5000, "handicap_points": 0.5},
            {"rank_difference_type": "1_sub", "bet_amount": 10000, "handicap_points": 0.5},
            {"rank_difference_type": "1_sub", "bet_amount": 20000, "handicap_points": 1.0},
            {"rank_difference_type": "1_sub", "bet_amount": 50000, "handicap_points": 1.0},
            {"rank_difference_type": "1_sub", "bet_amount": 100000, "handicap_points": 1.5},
            {"rank_difference_type": "1_sub", "bet_amount": 200000, "handicap_points": 1.5},
            
            # 1 main (±2 levels like K vs H)
            {"rank_difference_type": "1_main", "bet_amount": 5000, "handicap_points": 1.0},
            {"rank_difference_type": "1_main", "bet_amount": 10000, "handicap_points": 1.0},
            {"rank_difference_type": "1_main", "bet_amount": 20000, "handicap_points": 1.5},
            {"rank_difference_type": "1_main", "bet_amount": 50000, "handicap_points": 2.0},
            {"rank_difference_type": "1_main", "bet_amount": 100000, "handicap_points": 2.5},
            {"rank_difference_type": "1_main", "bet_amount": 200000, "handicap_points": 3.0},
            
            # 1.5 main (±3 levels like K vs H+)
            {"rank_difference_type": "1.5_main", "bet_amount": 5000, "handicap_points": 1.5},
            {"rank_difference_type": "1.5_main", "bet_amount": 10000, "handicap_points": 2.0},
            {"rank_difference_type": "1.5_main", "bet_amount": 20000, "handicap_points": 2.5},
            {"rank_difference_type": "1.5_main", "bet_amount": 50000, "handicap_points": 3.0},
            {"rank_difference_type": "1.5_main", "bet_amount": 100000, "handicap_points": 3.5},
            {"rank_difference_type": "1.5_main", "bet_amount": 200000, "handicap_points": 4.0},
            
            # 2 main (±4 levels like K vs G)
            {"rank_difference_type": "2_main", "bet_amount": 5000, "handicap_points": 2.0},
            {"rank_difference_type": "2_main", "bet_amount": 10000, "handicap_points": 2.5},
            {"rank_difference_type": "2_main", "bet_amount": 20000, "handicap_points": 3.0},
            {"rank_difference_type": "2_main", "bet_amount": 50000, "handicap_points": 4.0},
            {"rank_difference_type": "2_main", "bet_amount": 100000, "handicap_points": 4.5},
            {"rank_difference_type": "2_main", "bet_amount": 200000, "handicap_points": 5.0},
        ]
        
        for rule in handicap_data:
            resp = api_request(env, 'POST', 'handicap_rules', rule)
            if resp.status_code < 300:
                print(f"      ✅ {rule['rank_difference_type']} / {rule['bet_amount']/1000}K")
    
    print("\n📊 AFTER:")
    ranks_after = verify_ranks(env)
    
    resp = api_request(env, 'GET', 'handicap_rules?select=*')
    handicap_after = len(resp.json())
    
    print(f"\n🎯 Handicap rules: {handicap_after}")
    
    print("\n" + "=" * 60)
    if len(ranks_after) == 10 and handicap_after >= 24:
        print("✅ MIGRATION SUCCESSFUL!")
        print("   - K+ and I+ removed")
        print("   - 10 ranks with new ELO ranges")
        print("   - Detailed stability descriptions")
        print("   - Handicap rules populated")
    else:
        print("⚠️  Warning: Unexpected results")
        print(f"   Got: {len(ranks_after)} ranks, {handicap_after} rules")

if __name__ == '__main__':
    main()
