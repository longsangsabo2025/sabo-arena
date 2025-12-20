"""
ELON MODE V2: Smart check - Real users have auth (email/phone), demo users don't
First principles: If no email AND no phone = FAKE USER
"""
import psycopg2
import json
import sys

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🧠 SMART CHECK: Finding users WITHOUT auth credentials\n', flush=True)
print('=' * 70)

# Real logic: Users without email AND without phone = demo garbage
cur.execute("""
    SELECT 
        id,
        username,
        full_name,
        email,
        phone,
        rank,
        elo_rating,
        created_at
    FROM users 
    WHERE (email IS NULL OR email = '') 
      AND (phone IS NULL OR phone = '')
    ORDER BY created_at
""")

demo_users = cur.fetchall()

if not demo_users:
    print('✅ ZERO fake users. All users have proper auth credentials.')
    print('   Database is CLEAN.\n')
    conn.close()
    exit(0)

print(f'🔴 FOUND {len(demo_users)} FAKE USERS (no email, no phone):\n')

total_tournaments = 0
total_matches = 0
total_posts = 0

for uid, username, fullname, email, phone, rank, elo, created in demo_users:
    print(f'👤 {username} ({fullname})')
    print(f'   Email: {email or "NONE"} | Phone: {phone or "NONE"}')
    print(f'   Rank: {rank or "None"} | ELO: {elo}')
    print(f'   Created: {created.strftime("%Y-%m-%d %H:%M")}')
    print(f'   ID: {uid}')
    
    # Check activity
    cur.execute('SELECT COUNT(*) FROM tournament_participants WHERE user_id = %s', (uid,))
    tournaments = cur.fetchone()[0]
    total_tournaments += tournaments
    
    cur.execute('SELECT COUNT(*) FROM matches WHERE player1_id = %s OR player2_id = %s', (uid, uid))
    matches = cur.fetchone()[0]
    total_matches += matches
    
    cur.execute('SELECT COUNT(*) FROM posts WHERE author_id = %s', (uid,))
    posts = cur.fetchone()[0]
    total_posts += posts
    
    if tournaments > 0 or matches > 0 or posts > 0:
        print(f'   ⚠️  Activity: {tournaments} tournaments, {matches} matches, {posts} posts')
    else:
        print(f'   ✓ Clean (no activity)')
    
    print()

print('=' * 70)
print(f'\n📊 ANALYSIS:')
print(f'   • {len(demo_users)} fake accounts = database pollution')
print(f'   • {total_tournaments} tournament participations')
print(f'   • {total_matches} matches')
print(f'   • {total_posts} posts')
print(f'\n💡 ELON\'S VERDICT:')
print(f'   These are TEST ARTIFACTS. No real authentication.')
print(f'   Action: DELETE ALL')
print(f'\n🚀 Next: Run elon_nuke_demo.py\n')

conn.close()
