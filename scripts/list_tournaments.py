"""List all tournaments in the new database"""
from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

# List tournaments - get all columns
tournaments = supabase.table('tournaments').select('*').execute()
print('=== TOURNAMENTS ===')
for t in tournaments.data:
    print(f"ID: {t['id']}")
    print(f"  Columns: {list(t.keys())}")
    print()
