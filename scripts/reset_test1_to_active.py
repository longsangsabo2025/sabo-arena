import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from supabase import create_client, Client

url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
supabase: Client = create_client(url, key)

# Get tournament
tournament = supabase.table('tournaments').select('id, title, status').eq('title', 'test1').single().execute()
print(f"Current status: {tournament.data['status']}")

# Reset to ongoing
result = supabase.table('tournaments').update({
    'status': 'ongoing',
    'completed_at': None
}).eq('id', tournament.data['id']).execute()

print(f"✅ Reset tournament to ONGOING - ready for re-completion with rewards!")
