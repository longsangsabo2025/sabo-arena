import os
import re

def find_dead_files(project_root):
    lib_dir = os.path.join(project_root, "lib")
    test_dir = os.path.join(project_root, "test")
    
    # 1. Identify all Dart files in lib/
    all_dart_files = set()
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                full_path = os.path.abspath(os.path.join(root, file))
                all_dart_files.add(full_path)

    # 2. Identify all imports in lib/ and test/
    referenced_files = set()
    
    # Helper to resolve imports
    def resolve_import(current_file_path, import_path):
        # Handle package: imports
        if import_path.startswith("package:sabo_arena/"):
            relative_path = import_path.replace("package:sabo_arena/", "")
            return os.path.abspath(os.path.join(lib_dir, relative_path))
        
        # Handle relative imports
        elif not import_path.startswith("package:") and not import_path.startswith("dart:"):
            current_dir = os.path.dirname(current_file_path)
            return os.path.abspath(os.path.join(current_dir, import_path))
        
        return None

    # Scan directories
    scan_dirs = [lib_dir]
    if os.path.exists(test_dir):
        scan_dirs.append(test_dir)

    for scan_dir in scan_dirs:
        for root, dirs, files in os.walk(scan_dir):
            for file in files:
                if file.endswith(".dart"):
                    current_file_path = os.path.abspath(os.path.join(root, file))
                    
                    try:
                        with open(current_file_path, "r", encoding="utf-8", errors="ignore") as f:
                            content = f.read()
                            
                            # Regex for imports, exports, and parts
                            # Matches: import "..."; export "..."; part "...";
                            # Also handles conditional imports which are just more strings in the statement
                            # UPDATED: Matches any string ending in .dart inside quotes
                            matches = re.findall(r"[\"\u0027]([^\u0027\"]+\.dart)[\"\u0027]", content)
                            
                            for match in matches:
                                resolved = resolve_import(current_file_path, match)
                                if resolved and os.path.exists(resolved):
                                    referenced_files.add(resolved)
                    except Exception as e:
                        print(f"Error reading {current_file_path}: {e}")

    # 3. Calculate Dead Files
    # Exclude main.dart and other known entry points
    entry_points = {
        os.path.abspath(os.path.join(lib_dir, "main.dart")),
        os.path.abspath(os.path.join(lib_dir, "firebase_options.dart")),
        os.path.abspath(os.path.join(lib_dir, "generated_plugin_registrant.dart")),
    }
    
    dead_files = all_dart_files - referenced_files - entry_points
    
    return sorted(list(dead_files))

if __name__ == "__main__":
    current_dir = os.getcwd()
    print(f"Scanning for dead files in {current_dir}...")
    dead_files = find_dead_files(current_dir)
    
    if dead_files:
        print(f"\nFound {len(dead_files)} potentially dead files:")
        for f in dead_files:
            # Print relative path for readability
            rel_path = os.path.relpath(f, current_dir)
            print(f"- {rel_path}")
            
        # Save to file
        with open("dead_files_report.txt", "w") as f:
            for file in dead_files:
                f.write(f"{os.path.relpath(file, current_dir)}\n")
        print("\nReport saved to dead_files_report.txt")
    else:
        print("\nNo dead files found! Great job.")

