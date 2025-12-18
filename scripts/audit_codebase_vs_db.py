import os
import re

# Configuration
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR = os.path.join(PROJECT_ROOT, 'lib')
SNAPSHOT_FILE = os.path.join(PROJECT_ROOT, '_DATABASE_INFO', 'LIVE_SCHEMA_SNAPSHOT.md')

def load_live_tables():
    """Loads the list of tables from the snapshot file."""
    tables = set()
    try:
        with open(SNAPSHOT_FILE, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            start_reading = False
            for line in lines:
                if "## 📋 Table List" in line:
                    start_reading = True
                    continue
                if "## 🧠 Elon's Analysis" in line:
                    break
                if start_reading:
                    # Match lines like "1. table_name"
                    match = re.match(r'^\d+\.\s+([a-zA-Z0-9_]+)', line.strip())
                    if match:
                        tables.add(match.group(1))
    except FileNotFoundError:
        print(f"❌ Error: Snapshot file not found at {SNAPSHOT_FILE}")
        exit(1)
    return tables

def scan_codebase_for_tables():
    """Scans the lib directory for table usages."""
    used_tables = set()
    # Regex to find .from('table_name') or .from("table_name")
    # Also matches SupabaseTable('table_name') if used in annotations
    regex = re.compile(r"\.from\(['\"]([a-zA-Z0-9_]+)['\"]\)")
    
    for root, _, files in os.walk(LIB_DIR):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        matches = regex.findall(content)
                        for match in matches:
                            used_tables.add(match)
                except Exception as e:
                    print(f"⚠️ Error reading file {path}: {e}")
    return used_tables

def main():
    print("🚀 Elon Musk's Codebase vs Database Audit")
    print("----------------------------------------")

    # 1. Load Truth
    live_tables = load_live_tables()
    print(f"📊 Live Database Tables: {len(live_tables)}")

    # 2. Scan Code
    code_tables = scan_codebase_for_tables()
    print(f"💻 Tables Referenced in Code: {len(code_tables)}")

    # 3. Analyze
    print("\n----------------------------------------")
    print("🚨 CRITICAL MISMATCHES (Code references non-existent tables)")
    print("----------------------------------------")
    missing_in_db = code_tables - live_tables
    if missing_in_db:
        for table in sorted(missing_in_db):
            print(f"❌ {table} (Used in code, but NOT in DB)")
    else:
        print("✅ None. All code references point to existing tables.")

    print("\n----------------------------------------")
    print("💀 ZOMBIE TABLES (In DB, but NOT used in Code)")
    print("----------------------------------------")
    unused_in_code = live_tables - code_tables
    if unused_in_code:
        print(f"Found {len(unused_in_code)} unused tables.")
        # Print first 20 as sample
        for i, table in enumerate(sorted(unused_in_code)):
            if i < 20:
                print(f"⚠️ {table}")
        if len(unused_in_code) > 20:
            print(f"... and {len(unused_in_code) - 20} more.")
    else:
        print("✅ None. All DB tables are utilized.")

if __name__ == "__main__":
    main()
