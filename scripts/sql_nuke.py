"""ELON MODE: DIRECT SQL DELETE - NO MERCY"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

# Parse DB URL
db_url = os.getenv('SUPABASE_DB_DIRECT_URL')

print('🚀 ELON MODE: DIRECT DATABASE NUKE\n')

conn = psycopg2.connect(db_url)
cur = conn.cursor()

# Get tournament ID
cur.execute("SELECT id, title FROM tournaments WHERE title ILIKE '%test1%' LIMIT 1")
tid, title = cur.fetchone()
print(f'🎯 Target: {title} ({tid})\n')

# Count before
cur.execute(f"SELECT COUNT(*) FROM matches WHERE tournament_id = '{tid}'")
match_count = cur.fetchone()[0]
cur.execute(f"SELECT COUNT(*) FROM tournament_participants WHERE tournament_id = '{tid}'")
part_count = cur.fetchone()[0]

print(f'💥 NUKING:')
print(f'  - {match_count} matches')
print(f'  - {part_count} participants\n')

# DELETE
cur.execute(f"DELETE FROM matches WHERE tournament_id = '{tid}'")
cur.execute(f"DELETE FROM tournament_participants WHERE tournament_id = '{tid}'")
cur.execute(f"UPDATE tournaments SET status = 'draft', current_participants = 0 WHERE id = '{tid}'")

conn.commit()
cur.close()
conn.close()

print(f'✅ NUKED {match_count} matches')
print(f'✅ NUKED {part_count} participants')
print(f'✅ Reset tournament to DRAFT\n')
print(f'🎉 COMPLETE! Ready for testing')
