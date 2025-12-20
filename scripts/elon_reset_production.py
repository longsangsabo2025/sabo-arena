"""
🚀 ELON'S PRODUCTION RESET PROTOCOL
Reset ALL user stats to ZERO for clean production launch
"""
import psycopg2
import json
import sys

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
conn.autocommit = False  # Transaction mode
cur = conn.cursor()

print('🚀 ELON\'S PRODUCTION RESET')
print('=' * 70)

try:
    # Step 1: Preview what will be reset
    print('\n📊 Current State Before Reset:')
    cur.execute("""
        SELECT 
            COUNT(*) as users,
            SUM(COALESCE(spa_points, 0)) as total_spa,
            SUM(COALESCE(wins, 0)) as total_wins,
            SUM(COALESCE(losses, 0)) as total_losses,
            SUM(COALESCE(total_matches, 0)) as total_matches
        FROM users
        WHERE email NOT ILIKE '%saboarena.com%'  -- Exclude test accounts
    """)
    before = cur.fetchone()
    print(f'  Users: {before[0]}')
    print(f'  Total SPA: {before[1]:,}')
    print(f'  Total Wins: {before[2]:,}')
    print(f'  Total Losses: {before[3]:,}')
    print(f'  Total Matches: {before[4]:,}')
    
    # Check notifications count
    cur.execute('SELECT COUNT(*) FROM notifications')
    notif_count = cur.fetchone()[0]
    print(f'  Notifications: {notif_count:,}')
    
    # Check member_statistics
    cur.execute('SELECT COUNT(*) FROM member_statistics')
    member_stats = cur.fetchone()[0]
    print(f'  Member Stats Records: {member_stats:,}')
    
    # Confirmation
    print('\n⚠️  THIS WILL:')
    print('  1. Reset ALL user SPA points to 0')
    print('  2. Reset ALL win/loss statistics to 0')
    print('  3. Delete ALL notifications')
    print('  4. Reset ALL member_statistics to 0')
    print('  5. Keep user accounts and profiles intact')
    print('\n❓ Type "RESET PRODUCTION" to confirm: ', end='')
    confirm = input()
    
    if confirm != "RESET PRODUCTION":
        print('\n❌ Aborted. No changes made.')
        sys.exit(0)
    
    print('\n🔄 Executing Reset...\n')
    
    # Step 2: Reset user stats
    print('  [1/4] Resetting user SPA points...')
    cur.execute("""
        UPDATE users SET
            spa_points = 0,
            spa_points_won = 0,
            spa_points_lost = 0
        WHERE email NOT ILIKE '%saboarena.com%'
    """)
    print(f'        ✓ {cur.rowcount} users updated')
    
    # Step 3: Reset win/loss stats
    print('  [2/4] Resetting win/loss statistics...')
    cur.execute("""
        UPDATE users SET
            total_wins = 0,
            total_losses = 0,
            total_tournaments = 0,
            total_matches = 0,
            wins = 0,
            losses = 0,
            win_streak = 0,
            tournaments_played = 0,
            tournament_wins = 0,
            challenge_win_streak = 0,
            total_prize_pool = 0,
            total_games = 0,
            tournament_podiums = 0
        WHERE email NOT ILIKE '%saboarena.com%'
    """)
    print(f'        ✓ {cur.rowcount} users updated')
    
    # Step 4: Delete all notifications
    print('  [3/4] Deleting all notifications...')
    cur.execute('DELETE FROM notifications')
    print(f'        ✓ {cur.rowcount} notifications deleted')
    
    # Step 5: Reset member_statistics
    print('  [4/4] Resetting member statistics...')
    cur.execute("""
        UPDATE member_statistics SET
            matches_played = 0,
            matches_won = 0,
            matches_lost = 0,
            tournaments_joined = 0,
            tournaments_won = 0,
            total_score = 0,
            average_score = 0
    """)
    print(f'        ✓ {cur.rowcount} member stats updated')
    
    # Commit
    conn.commit()
    print('\n✅ COMMIT - All changes saved')
    
    # Verify final state
    print('\n📊 Final State After Reset:')
    cur.execute("""
        SELECT 
            COUNT(*) as users,
            SUM(COALESCE(spa_points, 0)) as total_spa,
            SUM(COALESCE(wins, 0)) as total_wins,
            SUM(COALESCE(losses, 0)) as total_losses,
            SUM(COALESCE(total_matches, 0)) as total_matches
        FROM users
        WHERE email NOT ILIKE '%saboarena.com%'
    """)
    after = cur.fetchone()
    print(f'  Users: {after[0]}')
    print(f'  Total SPA: {after[1]:,}')
    print(f'  Total Wins: {after[2]:,}')
    print(f'  Total Losses: {after[3]:,}')
    print(f'  Total Matches: {after[4]:,}')
    
    cur.execute('SELECT COUNT(*) FROM notifications')
    notif_final = cur.fetchone()[0]
    print(f'  Notifications: {notif_final:,}')
    
    print('\n🚀 PRODUCTION DATABASE READY FOR LAUNCH!')
    print('=' * 70)

except Exception as e:
    conn.rollback()
    print(f'\n❌ ERROR - ROLLBACK: {e}')
    sys.exit(1)
finally:
    conn.close()
