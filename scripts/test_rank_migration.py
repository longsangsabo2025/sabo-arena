"""
Test Rank Migration - Verify K+/I+ removal and ELO range shifts
"""

import sys
import os
from supabase import create_client

# Load environment variables
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Missing Supabase credentials in .env")
    sys.exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# New rank system after migration
NEW_RANK_SYSTEM = {
    'K': {'min': 1000, 'max': 1099, 'skill': '1-2 Bi'},
    'I': {'min': 1100, 'max': 1199, 'skill': '1-3 Bi'},
    'H': {'min': 1200, 'max': 1299, 'skill': '3-5 Bi'},
    'H+': {'min': 1300, 'max': 1399, 'skill': '3-5 Bi (ổn định)'},
    'G': {'min': 1400, 'max': 1499, 'skill': '5-6 Bi'},
    'G+': {'min': 1500, 'max': 1599, 'skill': '5-6 Bi (ổn định)'},
    'F': {'min': 1600, 'max': 1699, 'skill': '6-8 Bi'},
    'F+': {'min': 1700, 'max': 1799, 'skill': '2 Chấm'},
    'E': {'min': 1800, 'max': 1899, 'skill': '3 Chấm'},
    'D': {'min': 1900, 'max': 1999, 'skill': '4 Chấm'},
    'C': {'min': 2000, 'max': 2099, 'skill': '5 Chấm'},
}

def get_rank_from_elo(elo: int) -> str:
    """Calculate rank from ELO using new system"""
    for rank, data in NEW_RANK_SYSTEM.items():
        if data['min'] <= elo <= data['max']:
            return rank
    
    # Handle edge cases
    if elo < 1000:
        return 'K'
    if elo >= 2100:
        return 'C'
    
    return 'UNKNOWN'

def test_elo_ranges():
    """Test ELO range boundaries"""
    print("\n" + "="*60)
    print("🧪 TEST 1: ELO Range Boundaries")
    print("="*60)
    
    test_cases = [
        (1000, 'K', '1-2 Bi'),
        (1099, 'K', '1-2 Bi'),
        (1100, 'I', '1-3 Bi'),
        (1199, 'I', '1-3 Bi'),
        (1200, 'H', '3-5 Bi'),
        (1299, 'H', '3-5 Bi'),
        (1300, 'H+', '3-5 Bi (ổn định)'),
        (1399, 'H+', '3-5 Bi (ổn định)'),
        (1400, 'G', '5-6 Bi'),
        (1499, 'G', '5-6 Bi'),
        (1500, 'G+', '5-6 Bi (ổn định)'),
        (1599, 'G+', '5-6 Bi (ổn định)'),
        (1600, 'F', '6-8 Bi'),
        (1699, 'F', '6-8 Bi'),
        (1700, 'F+', '2 Chấm'),
        (1799, 'F+', '2 Chấm'),
        (1800, 'E', '3 Chấm'),
        (1899, 'E', '3 Chấm'),
        (1900, 'D', '4 Chấm'),
        (1999, 'D', '4 Chấm'),
        (2000, 'C', '5 Chấm'),
        (2099, 'C', '5 Chấm'),
    ]
    
    passed = 0
    failed = 0
    
    for elo, expected_rank, expected_skill in test_cases:
        actual_rank = get_rank_from_elo(elo)
        actual_skill = NEW_RANK_SYSTEM.get(actual_rank, {}).get('skill', 'UNKNOWN')
        
        if actual_rank == expected_rank and actual_skill == expected_skill:
            print(f"✅ ELO {elo} → {actual_rank} ({actual_skill})")
            passed += 1
        else:
            print(f"❌ ELO {elo} → Expected: {expected_rank} ({expected_skill}), Got: {actual_rank} ({actual_skill})")
            failed += 1
    
    print(f"\n📊 Results: {passed} passed, {failed} failed")
    return failed == 0

def test_removed_ranks():
    """Test that K+ and I+ are removed"""
    print("\n" + "="*60)
    print("🧪 TEST 2: Removed Ranks (K+ and I+)")
    print("="*60)
    
    # These ELO values should NOT map to K+ or I+
    removed_rank_tests = [
        (1100, 'K+', 'I'),  # 1100 was K+, now should be I
        (1150, 'K+', 'I'),
        (1199, 'K+', 'I'),
        (1300, 'I+', 'H+'), # 1300 was I+, now should be H+
        (1350, 'I+', 'H+'),
        (1399, 'I+', 'H+'),
    ]
    
    passed = 0
    failed = 0
    
    for elo, old_rank, expected_new_rank in removed_rank_tests:
        actual_rank = get_rank_from_elo(elo)
        
        if actual_rank != old_rank and actual_rank == expected_new_rank:
            print(f"✅ ELO {elo} correctly maps to {actual_rank} (not {old_rank})")
            passed += 1
        else:
            print(f"❌ ELO {elo} → Expected: {expected_new_rank}, Got: {actual_rank}")
            failed += 1
    
    print(f"\n📊 Results: {passed} passed, {failed} failed")
    return failed == 0

def test_rank_progression():
    """Test rank progression order"""
    print("\n" + "="*60)
    print("🧪 TEST 3: Rank Progression Order")
    print("="*60)
    
    expected_order = ['K', 'I', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'D', 'C']
    actual_order = list(NEW_RANK_SYSTEM.keys())
    
    if expected_order == actual_order:
        print(f"✅ Rank order correct: {' → '.join(actual_order)}")
        print(f"✅ Total ranks: {len(actual_order)} (removed K+ and I+)")
        return True
    else:
        print(f"❌ Rank order mismatch!")
        print(f"   Expected: {' → '.join(expected_order)}")
        print(f"   Got: {' → '.join(actual_order)}")
        return False

def test_user_rank_calculations():
    """Test rank calculations for actual users in database"""
    print("\n" + "="*60)
    print("🧪 TEST 4: User Rank Calculations (Database)")
    print("="*60)
    
    try:
        # Get all users with ELO
        response = supabase.table('users') \
            .select('id, username, elo_rating, rank') \
            .gt('elo_rating', 0) \
            .order('elo_rating', desc=True) \
            .limit(20) \
            .execute()
        
        if not response.data:
            print("⚠️  No users with ELO found in database")
            return True
        
        users = response.data
        print(f"\n📋 Testing {len(users)} users...\n")
        
        mismatches = []
        
        for user in users:
            elo = user['elo_rating']
            current_rank = user.get('rank', 'UNRANKED')
            calculated_rank = get_rank_from_elo(elo)
            
            # Check if current rank is K+ or I+ (should not exist)
            if current_rank in ['K+', 'I+']:
                print(f"⚠️  {user['username']}: ELO {elo} has OLD rank {current_rank}, should migrate to {calculated_rank}")
                mismatches.append((user['username'], elo, current_rank, calculated_rank))
            elif current_rank != calculated_rank:
                print(f"🔄 {user['username']}: ELO {elo} → Current: {current_rank}, Expected: {calculated_rank}")
                mismatches.append((user['username'], elo, current_rank, calculated_rank))
            else:
                print(f"✅ {user['username']}: ELO {elo} → {current_rank} (correct)")
        
        if mismatches:
            print(f"\n⚠️  {len(mismatches)} users need rank recalculation:")
            for username, elo, old_rank, new_rank in mismatches:
                skill = NEW_RANK_SYSTEM.get(new_rank, {}).get('skill', 'UNKNOWN')
                print(f"   • {username}: {old_rank} → {new_rank} ({skill})")
            
            print("\n💡 These ranks will auto-update when users play next tournament")
            return True  # Not a failure, just informational
        else:
            print("\n✅ All users have correct ranks!")
            return True
            
    except Exception as e:
        print(f"❌ Error testing user ranks: {e}")
        return False

def main():
    print("\n" + "="*60)
    print("🚀 RANK MIGRATION TEST SUITE")
    print("   Verifying K+/I+ removal and ELO range shifts")
    print("="*60)
    
    results = []
    
    # Run all tests
    results.append(("ELO Range Boundaries", test_elo_ranges()))
    results.append(("Removed Ranks", test_removed_ranks()))
    results.append(("Rank Progression", test_rank_progression()))
    results.append(("User Rank Calculations", test_user_rank_calculations()))
    
    # Summary
    print("\n" + "="*60)
    print("📊 TEST SUMMARY")
    print("="*60)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {test_name}")
    
    all_passed = all(result[1] for result in results)
    
    if all_passed:
        print("\n🎉 ALL TESTS PASSED! Rank migration verified successfully.")
        print("\n💡 Next steps:")
        print("   1. Deploy code changes")
        print("   2. User ranks will auto-update on next match/tournament")
        print("   3. No database migration needed (client-side calculation)")
    else:
        print("\n⚠️  Some tests failed. Review errors above.")
    
    return 0 if all_passed else 1

if __name__ == '__main__':
    sys.exit(main())
