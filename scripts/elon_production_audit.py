"""
ELON PRODUCTION AUDIT: Check what test data remains
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🔍 PRODUCTION READINESS AUDIT\n')
print('=' * 70)

# 1. Check tournaments with test names
cur.execute("""
    SELECT id, title, status, created_at, current_participants, max_participants
    FROM tournaments 
    WHERE title ILIKE '%test%' 
       OR title ILIKE '%demo%'
       OR title ILIKE '%64%'
    ORDER BY created_at DESC
""")
tournaments = cur.fetchall()

if tournaments:
    print(f'\n🔴 TEST TOURNAMENTS: {len(tournaments)} found\n')
    for tid, title, status, created, current, max_p in tournaments:
        print(f'  • {title} ({status})')
        print(f'    {current}/{max_p} players')
        print(f'    Created: {created.strftime("%Y-%m-%d")} | ID: {tid}')
else:
    print('\n✅ TOURNAMENTS: Clean (0 test tournaments)')

# 2. Check clubs with test names
cur.execute("""
    SELECT id, name, created_at
    FROM clubs 
    WHERE name ILIKE '%test%' 
       OR name ILIKE '%demo%'
    ORDER BY created_at DESC
    LIMIT 10
""")
clubs = cur.fetchall()

if clubs:
    print(f'\n🔴 TEST CLUBS: {len(clubs)} found\n')
    for cid, name, created in clubs:
        print(f'  • {name}')
        print(f'    Created: {created.strftime("%Y-%m-%d")} | ID: {cid}')
else:
    print('\n✅ CLUBS: Clean (0 test clubs)')

# 3. Total users remaining
cur.execute('SELECT COUNT(*) FROM users')
total_users = cur.fetchone()[0]

# 4. Total tournaments
cur.execute('SELECT COUNT(*) FROM tournaments')
total_tournaments = cur.fetchone()[0]

# 5. Total matches
cur.execute('SELECT COUNT(*) FROM matches')
total_matches = cur.fetchone()[0]

# 6. Total clubs
cur.execute('SELECT COUNT(*) FROM clubs')
total_clubs = cur.fetchone()[0]

# 7. Check for @saboarena.com emails (might be fake)
cur.execute("""
    SELECT COUNT(*) FROM users 
    WHERE email LIKE '%@saboarena.com'
""")
saboarena_emails = cur.fetchone()[0]

# 8. Posts
cur.execute('SELECT COUNT(*) FROM posts')
total_posts = cur.fetchone()[0]

print('\n' + '=' * 70)
print('\n📊 DATABASE STATISTICS:\n')
print(f'   Users: {total_users}')
print(f'   Tournaments: {total_tournaments}')
print(f'   Matches: {total_matches}')
print(f'   Clubs: {total_clubs}')
print(f'   Posts: {total_posts}')
print(f'   Users with @saboarena.com: {saboarena_emails}')

print('\n💡 RECOMMENDATIONS:\n')
if len(tournaments) > 0:
    print('   ⚠️  Delete test tournaments')
if len(clubs) > 0:
    print('   ⚠️  Delete test clubs')
if saboarena_emails > 0:
    print('   ⚠️  Check @saboarena.com emails (might be test accounts)')
if total_tournaments == 0 and total_matches == 0:
    print('   ✅ Ready for production launch')
    
print()

conn.close()
