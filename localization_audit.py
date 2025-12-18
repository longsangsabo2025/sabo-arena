import os
import re

# Configuration
PROJECT_ROOT = r'd:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app\lib'
IGNORE_DIRS = ['generated', 'l10n', 'firebase_options.dart']
IGNORE_FILES = ['.g.dart', '.freezed.dart']

# Regex patterns
# 1. Safe Text widgets: Text('String') or Text("String")
TEXT_WIDGET_PATTERN = re.compile(r"Text\s*\(\s*(['\"])(.*?)\1")
# 2. Const detection: const ... Text('String') - simplistic check
CONST_PATTERN = re.compile(r"const\s+.*Text")

def scan_project():
    stats = {
        'total_files': 0,
        'safe_text_widgets': 0,
        'risky_const_widgets': 0,
        'logic_strings': 0, # Strings not in Text widgets
        'files_with_issues': []
    }

    print(f"Scanning {PROJECT_ROOT}...\n")

    for root, dirs, files in os.walk(PROJECT_ROOT):
        # Filter ignored directories
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        for file in files:
            if not file.endswith('.dart'):
                continue
            if any(ignored in file for ignored in IGNORE_FILES):
                continue

            file_path = os.path.join(root, file)
            stats['total_files'] += 1
            
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
                # Check for Text widgets
                text_matches = TEXT_WIDGET_PATTERN.finditer(content)
                file_has_text = False
                
                for match in text_matches:
                    string_content = match.group(2)
                    # Skip empty strings or variable interpolations roughly
                    if not string_content or '$' in string_content:
                        continue
                        
                    # Check if this line or previous lines imply const
                    # This is a heuristic, not a full AST parser
                    start_index = match.start()
                    preceding_text = content[max(0, start_index-50):start_index]
                    
                    if 'const' in preceding_text:
                        stats['risky_const_widgets'] += 1
                    else:
                        stats['safe_text_widgets'] += 1
                    
                    file_has_text = True

                # Rough count of all other strings (Logic strings)
                # This finds all strings, then we subtract the Text widget ones roughly
                all_strings = len(re.findall(r"(['\"])(.*?)\1", content))
                text_widget_count = len(list(TEXT_WIDGET_PATTERN.finditer(content)))
                stats['logic_strings'] += max(0, all_strings - text_widget_count)

                if file_has_text:
                    stats['files_with_issues'].append(file_path)

    return stats

if __name__ == "__main__":
    stats = scan_project()
    
    print("-" * 50)
    print("AUDIT REPORT (BÁO CÁO RỦI RO)")
    print("-" * 50)
    print(f"Total Dart files scanned: {stats['total_files']}")
    print(f"\n[SAFE] Text Widgets found: {stats['safe_text_widgets']}")
    print("  -> These are safe to automate (mostly).")
    
    print(f"\n[RISKY] Const Text Widgets: {stats['risky_const_widgets']}")
    print("  -> RISK: Replacing these will cause syntax errors unless 'const' is removed.")
    
    print(f"\n[DANGEROUS] Logic/Other Strings: ~{stats['logic_strings']}")
    print("  -> RISK: These are IDs, Assets, Keys. DO NOT TOUCH automatically.")
    
    print("-" * 50)
    print("RECOMMENDATION:")
    if stats['risky_const_widgets'] > 0:
        print("⚠️  High Risk of 'const' errors. Use a smart script that removes 'const'.")
    else:
        print("✅  Low Risk of 'const' errors.")
        
    print(f"Suggest targeting only the {len(stats['files_with_issues'])} UI files first.")
