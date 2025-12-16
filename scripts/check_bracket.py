from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

tournament_id = 'e555beb9-9b15-4b01-b299-fb95863b76d4'
result = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('match_number').execute()

print('Match# | D.Order | Bracket | Round | WinAdvTo | LosAdvTo | Status')
print('-' * 90)
for m in result.data:
    wat = str(m.get('winner_advances_to', '')) if m.get('winner_advances_to') else '-'
    lat = str(m.get('loser_advances_to', '')) if m.get('loser_advances_to') else '-'
    do = str(m.get('display_order', '')) if m.get('display_order') else '-'
    bt = m.get('bracket_type') or 'N/A'
    status = m.get('status') or 'N/A'
    print(f"{m['match_number']:6} | {do:7} | {bt:7} | R{str(m['round_number']):4} | {wat:8} | {lat:8} | {status}")
