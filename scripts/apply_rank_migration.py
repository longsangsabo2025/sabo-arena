"""
Apply Rank System Migration to Supabase
- Remove K+ and I+ ranks
- Shift ELO ranges down by 100
- Populate handicap rules
"""
import json
from supabase import create_client

# Load env
with open('env.json') as f:
    env = json.load(f)

supabase = create_client(env['SUPABASE_URL'], env['SUPABASE_ANON_KEY'])

print("🚀 RANK SYSTEM MIGRATION 2025")
print("=" * 60)

# Step 1: Read current state
print("\n📊 BEFORE MIGRATION:")
result = supabase.table('rank_system').select('rank_code, elo_min, elo_max').order('elo_min').execute()
print(f"  Total ranks: {len(result.data)}")
for row in result.data:
    print(f"  {row['rank_code']:3s} | {row['elo_min']}-{row.get('elo_max') or 'MAX'}")

# Step 2: Confirm
print("\n⚠️  This migration will:")
print("  1. DELETE K+ and I+ ranks")
print("  2. SHIFT all ELO ranges down by 100")
print("  3. ADD detailed stability descriptions")
print("  4. POPULATE handicap_rules table")

confirm = input("\n👉 Continue? (yes/no): ")
if confirm.lower() != 'yes':
    print("❌ Migration cancelled.")
    exit(0)

# Step 3: Execute migrations
print("\n🔧 Executing migrations...")

# Read SQL files
with open('sql_migrations/rank_system_migration_2025_remove_kplus_iplus.sql') as f:
    rank_migration_sql = f.read()

with open('sql_migrations/populate_handicap_rules.sql') as f:
    handicap_sql = f.read()

print("\n⚠️  NOTE: SQL execution requires service role key or direct database access")
print("   Please run these SQL files manually in Supabase SQL Editor:")
print("   1. sql_migrations/rank_system_migration_2025_remove_kplus_iplus.sql")
print("   2. sql_migrations/populate_handicap_rules.sql")

print("\n✅ SQL files created and ready!")
print("   After running SQL, verify with: python scripts/check_rank_tables.py")
