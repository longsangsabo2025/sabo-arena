import os
import shutil

def move_dead_files():
    report_file = 'dead_files_report.txt'
    trash_dir = '_TRASH'

    if not os.path.exists(report_file):
        print(f"Report file {report_file} not found.")
        return

    with open(report_file, 'r') as f:
        files = [line.strip() for line in f.readlines() if line.strip()]

    print(f"Found {len(files)} files to move to {trash_dir}...")

    moved_count = 0
    not_found_count = 0

    for file_path in files:
        # Handle potential windows backslashes in the report
        clean_path = file_path.replace('\\', '/')
        
        if os.path.exists(clean_path):
            dest_path = os.path.join(trash_dir, clean_path)
            dest_folder = os.path.dirname(dest_path)
            
            os.makedirs(dest_folder, exist_ok=True)
            
            try:
                shutil.move(clean_path, dest_path)
                print(f"Moved: {clean_path}")
                moved_count += 1
            except Exception as e:
                print(f"Error moving {clean_path}: {e}")
        else:
            print(f"Not found (already deleted?): {clean_path}")
            not_found_count += 1

    print(f"\nOperation Complete.")
    print(f"Moved: {moved_count}")
    print(f"Not Found: {not_found_count}")

if __name__ == "__main__":
    move_dead_files()
