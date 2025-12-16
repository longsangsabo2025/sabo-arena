"""
Reset DE16 bracket for testing auto-advancement
- Keep Round 1 player assignments (player1_id, player2_id)
- Clear all scores, winners, and statuses
- Clear player assignments in Round 2+ matches
"""
from supabase import create_client

# NEW Supabase project (mogjjvscxjwvhtpkrlqr)
url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

tournament_id = 'e555beb9-9b15-4b01-b299-fb95863b76d4'

# Get all matches
matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('display_order').execute()

print(f"Found {len(matches.data)} matches")

# Separate Round 1 and later rounds
round1_matches = [m for m in matches.data if 1101 <= m['display_order'] <= 1108]
later_matches = [m for m in matches.data if m['display_order'] > 1108 or m['display_order'] < 1101]

print(f"\n=== RESETTING BRACKET ===")
print(f"Round 1 matches: {len(round1_matches)} - will reset scores/winner, keep players")
print(f"Later matches: {len(later_matches)} - will reset everything including player assignments")

# Reset Round 1 matches - keep player assignments
for m in round1_matches:
    result = supabase.table('matches').update({
        'player1_score': None,
        'player2_score': None,
        'winner_id': None,
        'status': 'pending'
    }).eq('id', m['id']).execute()
    print(f"  Reset R1 match {m['display_order']}: {m['player1_id'][:8] if m['player1_id'] else 'N/A'}... vs {m['player2_id'][:8] if m['player2_id'] else 'N/A'}...")

# Reset later matches - clear player assignments too
for m in later_matches:
    result = supabase.table('matches').update({
        'player1_id': None,
        'player2_id': None,
        'player1_score': None,
        'player2_score': None,
        'winner_id': None,
        'status': 'pending'
    }).eq('id', m['id']).execute()
    print(f"  Reset match {m['display_order']}: cleared all")

print("\n✅ Bracket reset complete!")
print("Round 1 has players assigned, ready for score entry")
print("Later rounds are empty, waiting for auto-advancement")
