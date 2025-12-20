"""FINAL ELON NUKE - Simple and direct"""
import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

s = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_ROLE_KEY'))

print('💥 FINAL NUKE OF TEST1\n')

# Get ID
t = s.table('tournaments').select('id, title').ilike('title', '%test1%').single().execute()
tid = t.data['id']
print(f'Target: {t.data["title"]} ({tid})\n')

# Nuke matches
print('Deleting matches...')
s.table('matches').delete().eq('tournament_id', tid).execute()
print('✅ Matches deleted')

# Nuke participants  
print('Deleting participants...')
s.table('tournament_participants').delete().eq('tournament_id', tid).execute()
print('✅ Participants deleted')

# Reset tournament
print('Resetting tournament...')
s.table('tournaments').update({'status': 'draft', 'current_participants': 0}).eq('id', tid).execute()
print('✅ Tournament reset to DRAFT')

print('\n🎉 DONE! Test1 is now EMPTY and ready for testing')
