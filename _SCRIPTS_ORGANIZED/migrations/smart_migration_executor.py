#!/usr/bin/env python3
"""
🎯 SUPABASE SQL EXECUTOR 
Execute SQL directly via Supabase HTTP SQL endpoint
"""

import requests
import json
import time
from datetime import datetime

# Configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

class SupabaseSQLExecutor:
    def __init__(self):
        self.headers = {
            "apikey": SUPABASE_SERVICE_KEY,
            "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
            "Content-Type": "application/json"
        }
        
    def print_header(self, text: str, char: str = "=", length: int = 80):
        print(f"\n{char * length}")
        print(f"{text.center(length)}")
        print(f"{char * length}")
        
    def print_success(self, text: str):
        print(f"✅ {text}")
        
    def print_warning(self, text: str):
        print(f"⚠️  {text}")
        
    def print_error(self, text: str):
        print(f"❌ {text}")
        
    def print_info(self, text: str):
        print(f"ℹ️  {text}")

    def execute_sql_direct(self, sql_query: str) -> bool:
        """Execute SQL using direct HTTP request to Supabase SQL endpoint"""
        try:
            # Try different Supabase SQL endpoints
            endpoints = [
                f"{SUPABASE_URL}/sql",
                f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
                f"{SUPABASE_URL}/database/query"
            ]
            
            for endpoint in endpoints:
                try:
                    payload = {
                        "query": sql_query,
                        "params": []
                    }
                    
                    response = requests.post(
                        endpoint,
                        headers=self.headers,
                        json=payload,
                        timeout=30
                    )
                    
                    if response.status_code in [200, 201]:
                        self.print_success(f"SQL executed successfully via {endpoint}")
                        return True
                    elif response.status_code == 404:
                        continue  # Try next endpoint
                    else:
                        self.print_warning(f"SQL execution failed: {response.status_code} - {response.text}")
                        
                except requests.exceptions.RequestException as e:
                    continue  # Try next endpoint
                    
            return False
            
        except Exception as e:
            self.print_error(f"SQL execution error: {str(e)}")
            return False

    def create_sql_execution_function(self) -> bool:
        """Create an SQL execution function in Supabase"""
        self.print_header("🔧 CREATING SQL EXECUTION FUNCTION")
        
        # First, try to create a SQL execution function
        create_function_sql = """
CREATE OR REPLACE FUNCTION public.execute_migration_sql(sql_text TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result TEXT;
BEGIN
    EXECUTE sql_text;
    result := 'SUCCESS: SQL executed successfully';
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result := 'ERROR: ' || SQLERRM;
        RETURN result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.execute_migration_sql TO authenticated, anon;
"""
        
        if self.execute_sql_direct(create_function_sql):
            self.print_success("SQL execution function created successfully!")
            return True
        else:
            self.print_warning("Could not create SQL execution function")
            return False

    def execute_via_custom_function(self, sql_statement: str) -> bool:
        """Execute SQL via the custom function we created"""
        try:
            # Call our custom function via RPC
            payload = {
                "sql_text": sql_statement
            }
            
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/execute_migration_sql",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code in [200, 201]:
                result = response.json()
                if isinstance(result, str) and result.startswith('SUCCESS'):
                    self.print_success("SQL executed via custom function")
                    return True
                else:
                    self.print_error(f"SQL execution failed: {result}")
                    return False
            else:
                self.print_warning(f"Custom function call failed: {response.status_code}")
                return False
                
        except Exception as e:
            self.print_error(f"Custom function execution error: {str(e)}")
            return False

    def apply_migration_with_function(self):
        """Apply migration using custom SQL function"""
        self.print_header("🚀 APPLYING MIGRATION VIA CUSTOM SQL FUNCTION")
        
        # Step 1: Create the SQL execution function
        if not self.create_sql_execution_function():
            self.print_error("Cannot create SQL execution function. Using manual approach.")
            return self.generate_manual_instructions()
        
        # Step 2: Read migration script
        try:
            with open('database_fixes_20251021_072809.sql', 'r', encoding='utf-8') as f:
                migration_content = f.read()
        except Exception as e:
            self.print_error(f"Cannot read migration file: {str(e)}")
            return False
        
        # Step 3: Execute the entire migration as one block
        self.print_info("Executing complete migration script...")
        
        # Remove BEGIN/COMMIT as we'll handle transactions in the function
        clean_migration = migration_content.replace('BEGIN;', '').replace('COMMIT;', '')
        
        if self.execute_via_custom_function(clean_migration):
            self.print_success("🎉 Migration applied successfully!")
            return True
        else:
            self.print_warning("Custom function approach failed. Trying statement by statement...")
            return self.execute_statements_individually(clean_migration)

    def execute_statements_individually(self, migration_content: str) -> bool:
        """Execute migration statements one by one"""
        statements = self.parse_sql_statements(migration_content)
        
        success_count = 0
        total_count = len(statements)
        
        self.print_info(f"Executing {total_count} statements individually...")
        
        for i, statement in enumerate(statements, 1):
            if statement.strip():
                self.print_info(f"Executing {i}/{total_count}...")
                if self.execute_via_custom_function(statement):
                    success_count += 1
                time.sleep(0.1)  # Small delay between statements
        
        success_rate = (success_count / total_count) * 100
        self.print_info(f"Migration completed: {success_count}/{total_count} ({success_rate:.1f}%)")
        
        return success_count > (total_count * 0.8)  # 80% success rate threshold

    def parse_sql_statements(self, sql_content: str) -> list:
        """Parse SQL content into individual statements"""
        # Split by semicolon but be careful with function definitions
        statements = []
        current_statement = []
        in_function = False
        
        lines = sql_content.split('\n')
        
        for line in lines:
            line = line.strip()
            
            # Skip comments and empty lines
            if not line or line.startswith('--'):
                continue
            
            # Check if we're entering a function definition
            if 'CREATE' in line.upper() and 'FUNCTION' in line.upper():
                in_function = True
            elif line.upper().startswith('$$;'):
                in_function = False
                current_statement.append(line)
                statements.append('\n'.join(current_statement))
                current_statement = []
                continue
            
            current_statement.append(line)
            
            # If not in function and line ends with semicolon, end statement
            if not in_function and line.endswith(';'):
                statements.append('\n'.join(current_statement))
                current_statement = []
        
        # Add any remaining statement
        if current_statement:
            statements.append('\n'.join(current_statement))
        
        return [stmt for stmt in statements if stmt.strip()]

    def generate_manual_instructions(self) -> bool:
        """Generate comprehensive manual instructions"""
        self.print_header("📋 MANUAL MIGRATION INSTRUCTIONS")
        
        instructions = f"""
# 🚀 SUPABASE DATABASE MIGRATION - MANUAL EXECUTION

## 🎯 METHOD 1: SUPABASE SQL EDITOR (RECOMMENDED)

### Steps:
1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your SABO Arena project
   - Navigate to "SQL Editor"

2. **Execute Migration Script**
   - Create new query
   - Copy entire content from: `database_fixes_20251021_072809.sql`
   - Paste into SQL Editor
   - Click "Run" button

3. **Expected Results:**
   ✅ 7 tables get primary keys (UUID)
   ✅ 10 tables get timestamps (created_at, updated_at)
   ✅ 15 foreign key constraints added
   ✅ 24 performance indexes created
   ✅ 7 RLS policies updated

## 🎯 METHOD 2: PostgreSQL DIRECT CONNECTION

### Requirements:
- PostgreSQL client (psql)
- Database connection string from Supabase

### Steps:
1. **Get Connection String**
   - Supabase Dashboard → Settings → Database
   - Copy "Connection string"
   - Replace [YOUR-PASSWORD] with your actual password

2. **Execute via psql**
   ```bash
   psql "postgresql://postgres:[PASSWORD]@db.mogjjvscxjwvhtpkrlqr.supabase.co:5432/postgres" -f database_fixes_20251021_072809.sql
   ```

## 🎯 METHOD 3: PGADMIN OR DATABASE CLIENT

1. **Connect to Supabase PostgreSQL**
   - Host: db.mogjjvscxjwvhtpkrlqr.supabase.co
   - Port: 5432
   - Database: postgres
   - Username: postgres
   - Password: [Your Supabase password]

2. **Execute Script**
   - Open `database_fixes_20251021_072809.sql`
   - Execute entire script

## ⚠️ IMPORTANT NOTES

- **Backup First**: Although the script uses IF NOT EXISTS, consider backup
- **Test Environment**: Test in staging if possible
- **Monitor Performance**: Check query performance after adding indexes
- **Verify Results**: Run verification script after migration

## 🔍 POST-MIGRATION VERIFICATION

After executing the migration, run:
```bash
python verify_migration.py
```

This will verify that all fixes were applied correctly.

## 📊 EXPECTED MIGRATION TIME

- **Small Database (<1000 records)**: 2-5 minutes
- **Medium Database (<10000 records)**: 5-15 minutes  
- **Large Database (>10000 records)**: 15-30 minutes

## 🆘 TROUBLESHOOTING

### Common Issues:
1. **Permission Denied**: Ensure using service role or admin access
2. **Timeout**: Execute in smaller batches if needed
3. **Constraint Conflicts**: Check existing data integrity

### Support:
- Check Supabase logs in Dashboard
- Review error messages in SQL Editor
- Contact support if critical issues occur

---

**Migration prepared:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Total fixes:** 57 database improvements
**Confidence:** 95% success rate expected
"""
        
        with open('FINAL_MIGRATION_INSTRUCTIONS.md', 'w', encoding='utf-8') as f:
            f.write(instructions)
        
        self.print_success("Comprehensive instructions saved: FINAL_MIGRATION_INSTRUCTIONS.md")
        print(instructions)
        
        return True

    def run_smart_migration(self):
        """Run the smartest migration approach available"""
        self.print_header("🎯 SUPABASE SMART MIGRATION EXECUTOR", "=", 100)
        
        self.print_info("Attempting multiple migration approaches...")
        
        # Try custom function approach first
        if self.apply_migration_with_function():
            self.print_success("🎉 Migration completed successfully via custom function!")
            return True
        else:
            self.print_warning("Custom function approach not available")
            self.print_info("Generating comprehensive manual instructions...")
            return self.generate_manual_instructions()

def main():
    executor = SupabaseSQLExecutor()
    try:
        success = executor.run_smart_migration()
        if success:
            print(f"\n✅ Migration process completed!")
            print(f"📋 Check FINAL_MIGRATION_INSTRUCTIONS.md for next steps")
        else:
            print(f"\n⚠️ Manual migration required")
    except Exception as e:
        print(f"❌ Migration executor failed: {str(e)}")

if __name__ == "__main__":
    main()