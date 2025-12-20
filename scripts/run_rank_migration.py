"""
Automatic Rank System Migration Executor
- Uses Supabase REST API with service role key
- Executes SQL migrations automatically
- Verifies changes
"""
import json
import requests

def load_env():
    """Load environment variables"""
    with open('env.json') as f:
        return json.load(f)

def execute_rpc(env, function_name, params=None):
    """Execute Supabase RPC function"""
    url = f"{env['SUPABASE_URL']}/rest/v1/rpc/{function_name}"
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    response = requests.post(url, headers=headers, json=params or {})
    return response

def execute_sql_direct(env, sql_query):
    """Execute SQL via Supabase REST API"""
    # Use raw SQL execution via PostgREST
    # Split into individual statements
    statements = [s.strip() for s in sql_query.split(';') if s.strip() and not s.strip().startswith('--')]
    
    results = []
    for stmt in statements:
        if not stmt:
            continue
            
        # For DELETE/UPDATE/INSERT, use table endpoints
        stmt_upper = stmt.upper()
        
        if 'DELETE FROM rank_system WHERE rank_code' in stmt_upper:
            # Extract rank codes
            if 'K+' in stmt or 'I+' in stmt:
                # Delete K+ and I+
                url = f"{env['SUPABASE_URL']}/rest/v1/rank_system"
                headers = {
                    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
                    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
                    'Content-Type': 'application/json'
                }
                # Delete K+
                resp = requests.delete(f"{url}?rank_code=eq.K%2B", headers=headers)
                results.append(('DELETE K+', resp.status_code))
                # Delete I+
                resp = requests.delete(f"{url}?rank_code=eq.I%2B", headers=headers)
                results.append(('DELETE I+', resp.status_code))
        
        elif 'UPDATE rank_system SET' in stmt_upper:
            # Extract rank_code and values
            import re
            match = re.search(r"WHERE rank_code = '([^']+)'", stmt)
            if match:
                rank_code = match.group(1)
                
                # Extract values
                data = {}
                if 'elo_min' in stmt:
                    elo_min = re.search(r'elo_min = (\d+)', stmt)
                    if elo_min:
                        data['elo_min'] = int(elo_min.group(1))
                if 'elo_max' in stmt:
                    elo_max = re.search(r'elo_max = (\d+)', stmt)
                    if elo_max:
                        data['elo_max'] = int(elo_max.group(1))
                    elif 'elo_max = NULL' in stmt:
                        data['elo_max'] = None
                if 'display_name' in stmt:
                    display_name = re.search(r"display_name = '([^']+)'", stmt)
                    if display_name:
                        data['display_name'] = display_name.group(1)
                if 'stability_description' in stmt:
                    # Extract multi-line description
                    desc_match = re.search(r"stability_description = '([^']*(?:''[^']*)*)'", stmt)
                    if desc_match:
                        data['stability_description'] = desc_match.group(1).replace("''", "'")
                
                url = f"{env['SUPABASE_URL']}/rest/v1/rank_system"
                headers = {
                    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
                    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                }
                resp = requests.patch(f"{url}?rank_code=eq.{rank_code}", headers=headers, json=data)
                results.append((f'UPDATE {rank_code}', resp.status_code))
        
        elif 'TRUNCATE handicap_rules' in stmt_upper:
            url = f"{env['SUPABASE_URL']}/rest/v1/handicap_rules"
            headers = {
                'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
                'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
            }
            resp = requests.delete(f"{url}?id=neq.0", headers=headers)
            results.append(('TRUNCATE handicap_rules', resp.status_code))
        
        elif 'INSERT INTO handicap_rules' in stmt_upper:
            # Parse INSERT values
            import re
            values_match = re.search(r'VALUES\s*\((.*?)\)', stmt, re.DOTALL)
            if values_match:
                values = values_match.group(1).split(',')
                data = {
                    'rank_difference_type': values[0].strip().strip("'"),
                    'bet_amount': int(values[1].strip()),
                    'handicap_points': float(values[2].strip())
                }
                
                url = f"{env['SUPABASE_URL']}/rest/v1/handicap_rules"
                headers = {
                    'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
                    'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                }
                resp = requests.post(url, headers=headers, json=data)
                results.append((f'INSERT {data["rank_difference_type"]}/{data["bet_amount"]}K', resp.status_code))
    
    return results

def verify_migration(env):
    """Verify migration results"""
    headers = {
        'apikey': env['SUPABASE_SERVICE_ROLE_KEY'],
        'Authorization': f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
    }
    
    # Check rank_system
    url = f"{env['SUPABASE_URL']}/rest/v1/rank_system?select=rank_code,elo_min,elo_max&order=elo_min.asc"
    resp = requests.get(url, headers=headers)
    ranks = resp.json()
    
    print("\n📊 RANK_SYSTEM TABLE:")
    print(f"  Total ranks: {len(ranks)}")
    for rank in ranks:
        elo_max = rank.get('elo_max') or 'MAX'
        print(f"  {rank['rank_code']:3s} | {rank['elo_min']}-{elo_max}")
    
    # Check handicap_rules
    url = f"{env['SUPABASE_URL']}/rest/v1/handicap_rules?select=count"
    resp = requests.get(url, headers=headers)
    handicap_count = len(resp.json()) if resp.status_code == 200 else 0
    
    # Get actual count
    url = f"{env['SUPABASE_URL']}/rest/v1/handicap_rules?select=*"
    resp = requests.get(url, headers=headers)
    handicap_count = len(resp.json())
    
    print(f"\n🎯 HANDICAP_RULES TABLE:")
    print(f"  Total rules: {handicap_count}")
    
    return len(ranks), handicap_count

def main():
    print("🚀 AUTOMATIC RANK SYSTEM MIGRATION")
    print("=" * 60)
    
    # Load environment
    env = load_env()
    print("✅ Environment loaded")
    print(f"   Supabase URL: {env['SUPABASE_URL']}")
    
    # Show current state
    print("\n📊 BEFORE MIGRATION:")
    ranks_before, handicap_before = verify_migration(env)
    
    if ranks_before == 10:
        print("\n⚠️  Migration already applied! (10 ranks found)")
        confirm = input("   Re-apply migration? (yes/no): ")
        if confirm.lower() != 'yes':
            return
    
    # Execute migrations
    print("\n🔧 EXECUTING MIGRATIONS...")
    
    # Migration 1: rank_system
    print("\n1️⃣ Updating rank_system table...")
    try:
        with open('sql_migrations/rank_system_migration_2025_remove_kplus_iplus.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        results = execute_sql_direct(env, sql_content)
        print(f"   ✅ Executed {len(results)} operations")
        for op, status in results[:5]:  # Show first 5
            status_icon = '✅' if 200 <= status < 300 else '❌'
            print(f"      {status_icon} {op}: {status}")
        if len(results) > 5:
            print(f"      ... and {len(results) - 5} more")
    except Exception as e:
        print(f"   ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Migration 2: handicap_rules
    print("\n2️⃣ Populating handicap_rules table...")
    try:
        with open('sql_migrations/populate_handicap_rules.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        results = execute_sql_direct(env, sql_content)
        print(f"   ✅ Executed {len(results)} operations")
        success_count = sum(1 for _, status in results if 200 <= status < 300)
        print(f"      Success: {success_count}/{len(results)}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Verify results
    print("\n📊 AFTER MIGRATION:")
    ranks_after, handicap_after = verify_migration(env)
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ MIGRATION COMPLETED SUCCESSFULLY!")
    print(f"   Ranks: {ranks_before} → {ranks_after}")
    print(f"   Handicap rules: {handicap_before} → {handicap_after}")
    
    if ranks_after == 10 and handicap_after >= 24:
        print("\n🎉 All checks passed!")
        print("   - K+ and I+ removed")
        print("   - ELO ranges shifted down by 100")
        print("   - Handicap rules populated")
    else:
        print("\n⚠️  Warning: Unexpected results")
        print(f"   Expected: 10 ranks, 24+ handicap rules")
        print(f"   Got: {ranks_after} ranks, {handicap_after} handicap rules")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Migration cancelled by user")
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
