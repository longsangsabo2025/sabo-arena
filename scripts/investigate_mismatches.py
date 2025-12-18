import os
import re
import json

# Configuration
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_DIR = os.path.join(PROJECT_ROOT, 'lib')
SCHEMA_FILE = os.path.join(PROJECT_ROOT, '_DATABASE_INFO', 'LIVE_SCHEMA_DETAILS.json')

def load_schema():
    with open(SCHEMA_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def scan_for_missing_tables(missing_tables):
    print("\n🕵️‍♂️ INVESTIGATING MISSING TABLES USAGE:")
    print("----------------------------------------")
    
    # Regex to find table usage
    regexes = {table: re.compile(r"['\"]" + table + r"['\"]") for table in missing_tables}
    
    found_usages = {}

    for root, _, files in os.walk(LIB_DIR):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                        for i, line in enumerate(lines):
                            for table, regex in regexes.items():
                                if regex.search(line):
                                    if table not in found_usages:
                                        found_usages[table] = []
                                    found_usages[table].append(f"{os.path.relpath(path, PROJECT_ROOT)}:{i+1}")
                except Exception:
                    pass
    
    for table in missing_tables:
        if table in found_usages:
            print(f"\n❌ Table '{table}' is used in:")
            for usage in found_usages[table]:
                print(f"   - {usage}")
        else:
            print(f"\n❓ Table '{table}' was detected by regex but exact location search failed (check string interpolation).")

def check_users_table_columns(schema):
    print("\n🕵️‍♂️ CHECKING 'users' TABLE COLUMNS:")
    print("----------------------------------------")
    
    if 'users' not in schema:
        print("❌ 'users' table not found in DB!")
        return

    db_columns = set(schema['users'].keys())
    
    # Common columns expected in code (based on typical User models)
    # We scan the User model file to see what it expects
    user_model_path = os.path.join(LIB_DIR, 'models', 'user_model.dart') # Guessing path
    
    # If we can't find the specific model file easily, we scan for .fromJson usage involving 'users' context
    # or just look for strings that look like column names in files that mention 'users'
    
    print(f"✅ DB Columns for 'users': {', '.join(sorted(db_columns))}")

def main():
    schema = load_schema()
    live_tables = set(schema.keys())
    
    # Re-run the basic scan to get code tables
    code_tables = set()
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
                            code_tables.add(match)
                except Exception:
                    pass
    
    missing_tables = code_tables - live_tables
    
    if missing_tables:
        scan_for_missing_tables(missing_tables)
    else:
        print("✅ No missing tables found used in .from() calls.")

if __name__ == "__main__":
    main()
