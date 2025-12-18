import psycopg2
import sys

# Connection string from .env (Using Session Pooler as Direct URL had DNS issues)
DB_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"

def check_database_state():
    try:
        print("Connecting to database...")
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # 1. Check if get_user_ranking RPC exists
        print("\n--- Checking RPC: get_user_ranking ---")
        cur.execute("""
            SELECT routine_name 
            FROM information_schema.routines 
            WHERE routine_type = 'FUNCTION' 
            AND routine_name = 'get_user_ranking';
        """)
        rpc = cur.fetchone()
        if rpc:
            print("✅ RPC 'get_user_ranking' EXISTS.")
        else:
            print("❌ RPC 'get_user_ranking' DOES NOT EXIST.")

        # 2. Check if tournaments -> clubs FK exists
        print("\n--- Checking Foreign Key: tournaments -> clubs ---")
        cur.execute("""
            SELECT constraint_name 
            FROM information_schema.table_constraints 
            WHERE constraint_name = 'tournaments_club_id_fkey';
        """)
        fk = cur.fetchone()
        if fk:
            print("✅ Foreign Key 'tournaments_club_id_fkey' EXISTS.")
        else:
            print("❌ Foreign Key 'tournaments_club_id_fkey' DOES NOT EXIST.")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error connecting or querying: {e}")

if __name__ == "__main__":
    check_database_state()
