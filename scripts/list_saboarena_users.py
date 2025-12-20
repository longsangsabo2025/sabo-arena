"""
List all users with @saboarena.com email
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('👥 Users with @saboarena.com email:\n')
print('=' * 90)

cur.execute("""
    SELECT 
        display_name,
        username,
        email,
        rank,
        elo_rating,
        wins,
        losses,
        spa_points,
        created_at::date,
        last_seen::date
    FROM users 
    WHERE email ILIKE '%saboarena.com%'
    ORDER BY created_at DESC
""")

users = cur.fetchall()
print(f'Total: {len(users)} users\n')

for i, (name, username, email, rank, elo, wins, losses, spa, created, last_signin) in enumerate(users, 1):
    name_str = name or 'NO_NAME'
    username_str = username or 'no_username'
    rank_str = rank or 'NO_RANK'
    elo_str = str(elo) if elo else '0'
    wins_str = str(wins) if wins else '0'
    losses_str = str(losses) if losses else '0'
    spa_str = str(spa) if spa else '0'
    created_str = str(created) if created else 'unknown'
    signin_str = str(last_signin) if last_signin else 'never'
    
    print(f'{i:2d}. {name_str:20s} (@{username_str:15s})')
    print(f'    Email: {email}')
    print(f'    Rank: {rank_str:3s} | ELO: {elo_str:4s} | W/L: {wins_str}/{losses_str} | SPA: {spa_str}')
    print(f'    Created: {created_str} | Last signin: {signin_str}')
    print()

# Check if they have any tournament participations
print('=' * 90)
print('\n📊 Tournament Activity:\n')

cur.execute("""
    SELECT 
        u.display_name,
        u.email,
        COUNT(tp.id) as tournaments
    FROM users u
    LEFT JOIN tournament_participants tp ON u.id = tp.user_id
    WHERE u.email ILIKE '%saboarena.com%'
    GROUP BY u.id, u.display_name, u.email
    HAVING COUNT(tp.id) > 0
    ORDER BY COUNT(tp.id) DESC
""")

activity = cur.fetchall()
if activity:
    for name, email, count in activity:
        print(f'  • {name or "NO_NAME"} ({email}): {count} tournaments')
else:
    print('  ✅ No tournament participation found')

conn.close()
