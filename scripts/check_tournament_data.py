"""
Check tournament information in database vs UI display
"""
import json
import psycopg2
from datetime import datetime

# Load environment variables from env.json
with open('env.json', 'r') as f:
    env = json.load(f)

db_url = env['SUPABASE_DB_TRANSACTION_URL']

print("🔗 Connecting to database...")
conn = psycopg2.connect(db_url)
cursor = conn.cursor()
print("✅ Connected\n")

# Get the most recent tournament
print("📊 Checking recent tournaments...")
cursor.execute("""
    SELECT 
        id,
        name,
        start_date,
        club_id,
        tournament_type,
        max_players,
        entry_fee,
        prize,
        location,
        status,
        created_at
    FROM tournaments
    ORDER BY created_at DESC
    LIMIT 5;
""")

tournaments = cursor.fetchall()

if not tournaments:
    print("❌ No tournaments found in database")
else:
    print(f"✅ Found {len(tournaments)} recent tournaments:\n")
    
    for idx, t in enumerate(tournaments, 1):
        print(f"{'='*60}")
        print(f"Tournament #{idx}")
        print(f"{'='*60}")
        print(f"ID:            {t[0]}")
        print(f"Name:          {t[1]}")
        print(f"Start Date:    {t[2]}")
        print(f"Club ID:       {t[3]}")
        print(f"Type:          {t[4]}")
        print(f"Max Players:   {t[5]}")
        print(f"Entry Fee:     {t[6]} đ")
        print(f"Prize:         {t[7]}")
        print(f"Location:      {t[8]}")
        print(f"Status:        {t[9]}")
        print(f"Created:       {t[10]}")
        print()

# Get specific tournament by name if it matches "test1"
print("\n🔍 Searching for 'test1' tournament...")
cursor.execute("""
    SELECT 
        id,
        name,
        start_date,
        tournament_type,
        max_players,
        entry_fee,
        prize,
        location,
        status,
        description
    FROM tournaments
    WHERE name ILIKE '%test1%'
    ORDER BY created_at DESC
    LIMIT 1;
""")

test_tournament = cursor.fetchone()

if test_tournament:
    print("\n" + "="*60)
    print("🎯 FOUND 'test1' TOURNAMENT IN DATABASE")
    print("="*60)
    print(f"ID:            {test_tournament[0]}")
    print(f"Name:          {test_tournament[1]}")
    print(f"Start Date:    {test_tournament[2]}")
    print(f"Type:          {test_tournament[3]}")
    print(f"Max Players:   {test_tournament[4]}")
    print(f"Entry Fee:     {test_tournament[5]} đ")
    print(f"Prize:         {test_tournament[6]}")
    print(f"Location:      {test_tournament[7]}")
    print(f"Status:        {test_tournament[8]}")
    print(f"Description:   {test_tournament[9]}")
    print()
    
    # Compare with UI
    print("\n📱 FROM UI SCREENSHOT:")
    print("="*60)
    print("Name:          test1")
    print("Start Date:    27/12/2025")
    print("Type:          Vòng tròn (Round Robin)")
    print("Max Players:   16 người")
    print("Entry Fee:     100,000 đ")
    print("Prize:         Tất cả trình độ")
    print("Location:      601A Nguyễn An Ninh - Vũng Tàu")
    print()
    
    print("\n🔍 COMPARISON:")
    print("="*60)
    
    # Check each field
    db_date = test_tournament[2].strftime('%d/%m/%Y') if test_tournament[2] else 'N/A'
    ui_date = "27/12/2025"
    
    if db_date != ui_date:
        print(f"❌ Date mismatch: DB={db_date}, UI={ui_date}")
    else:
        print(f"✅ Date matches: {db_date}")
    
    db_type = test_tournament[3]
    ui_type = "Vòng tròn"
    type_match = db_type == 'round_robin' if ui_type == 'Vòng tròn' else False
    
    if not type_match:
        print(f"❌ Type mismatch: DB={db_type}, UI={ui_type}")
    else:
        print(f"✅ Type matches: {db_type}")
    
    db_max = test_tournament[4]
    ui_max = 16
    
    if db_max != ui_max:
        print(f"❌ Max players mismatch: DB={db_max}, UI={ui_max}")
    else:
        print(f"✅ Max players matches: {db_max}")
    
    db_fee = test_tournament[5]
    ui_fee = 100000
    
    if db_fee != ui_fee:
        print(f"❌ Entry fee mismatch: DB={db_fee}, UI={ui_fee}")
    else:
        print(f"✅ Entry fee matches: {db_fee:,} đ")
    
    db_location = test_tournament[7]
    ui_location = "601A Nguyễn An Ninh - Vũng Tàu"
    
    if db_location != ui_location:
        print(f"❌ Location mismatch:")
        print(f"   DB: {db_location}")
        print(f"   UI: {ui_location}")
    else:
        print(f"✅ Location matches: {db_location}")
        
else:
    print("❌ 'test1' tournament not found in database")

cursor.close()
conn.close()
