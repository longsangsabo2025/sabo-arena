#!/usr/bin/env python3
'''
Direct PostgreSQL Connection Script
Connects directly to Supabase PostgreSQL database
'''

import psycopg2
import os
from urllib.parse import urlparse

# Database connection string (you'll need to get this from Supabase dashboard)
# Go to Settings > Database > Connection string
DATABASE_URL = "postgresql://postgres:[YOUR-PASSWORD]@db.mogjjvscxjwvhtpkrlqr.supabase.co:5432/postgres"

def execute_migration_directly():
    try:
        # Parse connection URL
        url = urlparse(DATABASE_URL)
        
        # Connect to database
        conn = psycopg2.connect(
            host=url.hostname,
            port=url.port,
            database=url.path[1:],  # Remove leading '/'
            user=url.username,
            password=url.password
        )
        
        # Read migration script
        with open('database_fixes_20251021_072809.sql', 'r', encoding='utf-8') as f:
            migration_sql = f.read()
        
        # Execute migration
        cursor = conn.cursor()
        cursor.execute(migration_sql)
        conn.commit()
        
        print("✅ Migration executed successfully!")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")

if __name__ == "__main__":
    print("🚀 Direct PostgreSQL Migration")
    print("⚠️  Make sure to update DATABASE_URL with your password")
    # execute_migration_directly()  # Uncomment when ready
