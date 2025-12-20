"""
Check actual tournaments table schema
"""
import json
import psycopg2

# Load environment variables from env.json
with open('env.json', 'r') as f:
    env = json.load(f)

db_url = env['SUPABASE_DB_TRANSACTION_URL']

print("🔗 Connecting to database...")
conn = psycopg2.connect(db_url)
cursor = conn.cursor()
print("✅ Connected\n")

# Get tournaments table schema
print("📋 Checking 'tournaments' table schema...")
cursor.execute("""
    SELECT column_name, data_type, character_maximum_length
    FROM information_schema.columns
    WHERE table_schema = 'public' 
    AND table_name = 'tournaments'
    ORDER BY ordinal_position;
""")

columns = cursor.fetchall()

if not columns:
    print("❌ 'tournaments' table not found!")
else:
    print(f"✅ Found {len(columns)} columns in 'tournaments' table:\n")
    print(f"{'Column Name':<30} {'Data Type':<20} {'Max Length'}")
    print("="*70)
    for col in columns:
        max_len = col[2] if col[2] else '-'
        print(f"{col[0]:<30} {col[1]:<20} {max_len}")

# Get sample tournament data
print("\n\n📊 Sample tournament data (5 most recent)...")
cursor.execute("""
    SELECT *
    FROM tournaments
    ORDER BY created_at DESC
    LIMIT 5;
""")

rows = cursor.fetchall()
col_names = [desc[0] for desc in cursor.description]

if not rows:
    print("❌ No tournaments found")
else:
    print(f"✅ Found {len(rows)} tournaments\n")
    for idx, row in enumerate(rows, 1):
        print(f"\n{'='*70}")
        print(f"Tournament #{idx}")
        print(f"{'='*70}")
        for col_name, value in zip(col_names, row):
            print(f"{col_name:<25}: {value}")

cursor.close()
conn.close()
