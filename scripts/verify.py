from dotenv import load_dotenv
import os
from supabase import create_client

load_dotenv()
s = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_ROLE_KEY'))

t = s.table('tournaments').select('id, title, status, current_participants').ilike('title', '%test1%').single().execute()
tid = t.data['id']

m = s.table('matches').select('id', count='exact').eq('tournament_id', tid).execute()
p = s.table('tournament_participants').select('id', count='exact').eq('tournament_id', tid).execute()

print(f'\n✅ Tournament: {t.data["title"]}')
print(f'📊 Status: {t.data["status"]}')
print(f'👥 Current participants: {t.data["current_participants"]}')
print(f'🏆 Matches in DB: {m.count}')
print(f'👥 Participants in DB: {p.count}')
print(f'\n{"🎉 CLEAN!" if m.count == 0 and p.count == 0 else "⚠️  Still has data"}')
