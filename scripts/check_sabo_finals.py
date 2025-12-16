"""Check SABO Finals structure"""
from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

tournament_id = 'e555beb9-9b15-4b01-b299-fb95863b76d4'
matches = supabase.table('matches').select('display_order,bracket_type,winner_advances_to,loser_advances_to').eq('tournament_id', tournament_id).gte('display_order', 4000).order('display_order').execute()

print('=== SABO FINALS STRUCTURE ===')
for m in matches.data:
    win_to = m['winner_advances_to'] if m['winner_advances_to'] else '-'
    lose_to = m['loser_advances_to'] if m['loser_advances_to'] else '-'
    print(f"D.Order: {m['display_order']} | Type: {m['bracket_type']} | Win->: {win_to} | Lose->: {lose_to}")
