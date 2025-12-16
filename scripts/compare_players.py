import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

TOURNAMENT_ID = 'e555beb9-9b15-4b01-b299-fb95863b76d4'

# New player list from image - 16 players with ranks
NEW_PLAYERS = [
    ("Lý Bảo", "I"),
    ("Bảo Lâm", "I"),
    ("Trọng Phúc", "I"),
    ("Quang Khải", "I"),
    ("Dương Hải", "I"),
    ("Đạo Chích Kid", "I"),
    ("Nguyễn Hiếu", "I+"),
    ("Anh Quốc", "I"),
    ("Quốc Bảo", "I"),
    ("Jayson Trường", "I"),
    ("Huy Cao", "I"),
    ("Tiến Còi", "I"),
    ("Tú Ngô", "I"),
    ("Hải Ly", "I"),
    ("Xìn Con 1", "K"),
    ("Văn Vũ", "I"),
]

conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
cur = conn.cursor()

# Get current participants
cur.execute("""
    SELECT tp.seed_number, u.id, u.full_name, u.display_name, u.rank
    FROM tournament_participants tp
    JOIN users u ON u.id = tp.user_id
    WHERE tp.tournament_id = %s
    ORDER BY tp.seed_number
""", (TOURNAMENT_ID,))

participants = cur.fetchall()

print("📋 Current participants in tournament:")
print("="*70)
print(f"{'Seed':<6} {'Current Name':<25} {'New Name':<25} {'Match?'}")
print("-"*70)

for i, (seed, user_id, full_name, display_name, rank) in enumerate(participants):
    current_name = display_name or full_name or "N/A"
    new_name = NEW_PLAYERS[i][0] if i < len(NEW_PLAYERS) else "N/A"
    new_rank = NEW_PLAYERS[i][1] if i < len(NEW_PLAYERS) else "N/A"
    match = "✅" if current_name == new_name else "❌"
    print(f"{seed:<6} {current_name:<25} {new_name:<25} {match}")

print("-"*70)
print(f"\nTotal participants: {len(participants)}")

cur.close()
conn.close()
