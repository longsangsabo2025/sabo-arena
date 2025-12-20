import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment
load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def verify_rewards():
    print("=" * 80)
    print("VERIFICATION: Tournament test1 Reward Distribution")
    print("=" * 80)
    
    # 1. Check tournament status
    print("\n1️⃣ TOURNAMENT STATUS:")
    tournament = supabase.table('tournaments').select('*').ilike('title', '%test1%').limit(1).single().execute()
    t = tournament.data
    print(f"   ID: {t.get('id')}")
    print(f"   Title: {t.get('title')}")
    print(f"   Status: {t.get('status')}")
    print(f"   Completed At: {t.get('completed_at')}")
    print(f"   Rewards Executed: {t.get('rewards_executed', False)}")
    
    tournament_id = t['id']
    
    # 2. Check tournament_results (source of truth for rewards)
    print("\n2️⃣ TOURNAMENT RESULTS TABLE:")
    results = supabase.table('tournament_results').select('*').eq('tournament_id', tournament_id).order('position').execute()
    if len(results.data) == 0:
        print("   ❌ NO RECORDS FOUND - Rewards NOT distributed!")
        return
    
    print(f"   ✅ Found {len(results.data)} player results")
    for r in results.data:
        print(f"   Position {r['position']}: {r['participant_id']} | ELO: {r['elo_change']:+d} | SPA: {r['spa_reward']}")
    
    # 3. Get user IDs from tournament_results
    user_ids = [r['participant_id'] for r in results.data]
    
    # 4. Check user profiles - ELO and SPA balance
    print("\n3️⃣ USER PROFILES (ELO & SPA Points):")
    users = supabase.table('users').select('id, username, elo_rating, spa_points').in_('id', user_ids).execute()
    
    user_map = {u['id']: u for u in users.data}
    for r in results.data:
        user = user_map.get(r['participant_id'])
        if user:
            username = user.get('username') or user.get('id', 'Unknown')[:8]
            elo = user.get('elo_rating') or 1000
            spa = user.get('spa_points') or 0
            print(f"   {username:<15} | ELO: {elo} | SPA: {spa}")
        else:
            print(f"   {str(r['participant_id'])[:15]:<15} | ❌ USER NOT FOUND")
    
    # 5. Check elo_history - verify ELO changes recorded
    print("\n4️⃣ ELO HISTORY (Verify ELO changes recorded):")
    elo_history = supabase.table('elo_history').select('*').eq('tournament_id', tournament_id).order('created_at', desc=True).execute()
    
    if len(elo_history.data) == 0:
        print("   ❌ NO ELO HISTORY RECORDS - ELO changes NOT recorded!")
    else:
        print(f"   ✅ Found {len(elo_history.data)} ELO history records")
        for eh in elo_history.data[:5]:  # Show first 5
            print(f"   User {eh['user_id']}: {eh['old_elo']} → {eh['new_elo']} ({eh['elo_change']:+d})")
    
    # 6. Check spa_transactions - verify SPA rewards recorded
    print("\n5️⃣ SPA TRANSACTIONS (Verify SPA rewards recorded):")
    spa_txns = supabase.table('spa_transactions').select('*').eq('reference_id', tournament_id).eq('transaction_type', 'tournament_reward').order('created_at', desc=True).execute()
    
    if len(spa_txns.data) == 0:
        print("   ❌ NO SPA TRANSACTIONS - SPA rewards NOT recorded!")
    else:
        print(f"   ✅ Found {len(spa_txns.data)} SPA transactions")
        for tx in spa_txns.data[:5]:  # Show first 5
            print(f"   User {tx['user_id']}: +{tx['amount']} SPA | Type: {tx.get('transaction_type')}")
    
    # 7. Check notifications
    print("\n6️⃣ NOTIFICATIONS (Verify users got notified):")
    notifications = supabase.table('notifications').select('*').in_('user_id', user_ids).eq('type', 'tournament_completed').order('created_at', desc=True).limit(20).execute()
    
    if len(notifications.data) == 0:
        print("   ⚠️  NO NOTIFICATIONS FOUND")
    else:
        print(f"   ✅ Found {len(notifications.data)} notifications")
        for notif in notifications.data[:5]:  # Show first 5
            print(f"   User {notif['user_id']}: {notif.get('title')} - {notif.get('message')}")
    
    # 8. SUMMARY
    print("\n" + "=" * 80)
    print("📊 SUMMARY:")
    print("=" * 80)
    print(f"✅ Tournament Status: {t.get('status')}")
    print(f"✅ Tournament Results: {len(results.data)} records")
    print(f"✅ User Profiles: {len(users.data)} users")
    print(f"✅ ELO History: {len(elo_history.data)} records")
    print(f"✅ SPA Transactions: {len(spa_txns.data)} records")
    print(f"✅ Notifications: {len(notifications.data)} records")
    
    if len(results.data) > 0 and len(elo_history.data) > 0 and len(spa_txns.data) > 0:
        print("\n🎉 ALL REWARDS SUCCESSFULLY DISTRIBUTED!")
    else:
        print("\n❌ REWARDS NOT FULLY DISTRIBUTED - Check details above")

if __name__ == '__main__':
    verify_rewards()
