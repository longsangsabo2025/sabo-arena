#!/usr/bin/env python3
"""
Script to migrate all AppBar to use CustomAppBar or AppBarTheme
"""

import os
import re
from pathlib import Path

# Base directory
BASE_DIR = Path(r"d:\0.APP\1810\saboarenav4\lib\presentation")

# Files to migrate
FILES_TO_MIGRATE = [
    "activity_history_screen/activity_history_screen.dart",
    "admin_dashboard_screen/admin_user_management_screen.dart",
    "admin_dashboard_screen/club_rank_change_management_screen.dart",
    "admin_dashboard_screen/system_admin_rank_management_screen.dart",
    "admin_tournament_completion_screen.dart",
    "admin_tournament_management_screen/admin_tournament_management_screen.dart",
    "club_main_screen/club_main_screen.dart",
    "club_notification_screen/club_notification_screen.dart",
    "club_profile_edit_screen/club_profile_edit_screen_simple.dart",
    "club_registration_screen/club_registration_screen.dart",
    "club_selection_screen/club_selection_screen.dart",
    "demo_bracket_screen/demo_bracket_screen.dart",
    "demo_qr_screen/demo_qr_screen.dart",
    "direct_messages_screen/direct_messages_screen.dart",
    "find_opponents_screen/find_opponents_screen.dart",
    "forgot_password_screen.dart",
    "friends_list_screen/friends_list_screen.dart",
    "leaderboard_screen/leaderboard_screen.dart",
    "member_communication_screen/member_communication_screen.dart",
    "membership/membership_plan_detail_screen.dart",
    "membership/membership_plans_screen.dart",
    "messaging_screen/messaging_screen.dart",
    "notification_analytics_dashboard.dart",
    "notification_settings_screen.dart",
    "phone_otp_verification/phone_otp_verification_screen.dart",
    "privacy_policy_screen/privacy_policy_screen.dart",
    "rank_management_screen/rank_management_screen.dart",
    "rank_registration_screen/rank_registration_screen.dart",
    "rank_statistics_screen/rank_statistics_screen.dart",
    "saved_posts_screen/saved_posts_screen.dart",
    "spa_management/admin_spa_management_screen.dart",
    "spa_management/club_spa_management_screen.dart",
    "spa_management/spa_reward_screen.dart",
    "terms_of_service_screen/terms_of_service_screen.dart",
    "tournament_creation_wizard/tournament_creation_wizard.dart",
    "tournament_detail_screen/single_tournament_management_screen.dart",
    "tournament_management_center/tournament_management_center_screen.dart",
]

def add_import_if_needed(content):
    """Add CustomAppBar import if not present"""
    if "import '../../widgets/custom_app_bar.dart';" in content:
        return content
    
    # Find the last import statement
    import_pattern = r"(import\s+['\"].*?['\"];)"
    imports = list(re.finditer(import_pattern, content))
    
    if imports:
        last_import = imports[-1]
        insert_pos = last_import.end()
        return content[:insert_pos] + "\nimport '../../widgets/custom_app_bar.dart';" + content[insert_pos:]
    
    return content

def migrate_simple_appbar(content):
    """Migrate simple AppBar without bottom parameter"""
    
    # Pattern 1: AppBar with title Text widget
    pattern1 = r"appBar:\s*AppBar\(\s*(?:backgroundColor:.*?,\s*)?(?:elevation:.*?,\s*)?(?:leading:.*?\),\s*)?title:\s*(?:const\s+)?Text\(\s*['\"]([^'\"]+)['\"]\s*(?:,\s*style:.*?)?\),?\s*(?:centerTitle:.*?,\s*)?"
    
    def replace1(match):
        title = match.group(1)
        return f"appBar: CustomAppBar(\n        title: '{title}',"
    
    content = re.sub(pattern1, replace1, content)
    
    # Pattern 2: AppBar with title variable
    pattern2 = r"appBar:\s*AppBar\(\s*(?:backgroundColor:.*?,\s*)?(?:elevation:.*?,\s*)?(?:leading:.*?\),\s*)?title:\s*Text\(\s*([a-zA-Z_][a-zA-Z0-9_\.?]*)\s*(?:,\s*style:.*?)?\),?\s*(?:centerTitle:.*?,\s*)?"
    
    def replace2(match):
        title_var = match.group(1)
        return f"appBar: CustomAppBar(\n        title: {title_var},"
    
    content = re.sub(pattern2, replace2, content)
    
    return content

def migrate_file(file_path):
    """Migrate a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Add import
        content = add_import_if_needed(content)
        
        # Migrate AppBar
        content = migrate_simple_appbar(content)
        
        # Only write if changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Migrated: {file_path.name}")
            return True
        else:
            print(f"⏭️  Skipped: {file_path.name} (no changes)")
            return False
            
    except Exception as e:
        print(f"❌ Error migrating {file_path.name}: {e}")
        return False

def main():
    """Main migration function"""
    print("🚀 Starting AppBar migration...\n")
    
    migrated = 0
    skipped = 0
    errors = 0
    
    for file_rel_path in FILES_TO_MIGRATE:
        file_path = BASE_DIR / file_rel_path
        
        if not file_path.exists():
            print(f"⚠️  File not found: {file_rel_path}")
            errors += 1
            continue
        
        result = migrate_file(file_path)
        if result:
            migrated += 1
        else:
            skipped += 1
    
    print(f"\n📊 Migration Summary:")
    print(f"   ✅ Migrated: {migrated}")
    print(f"   ⏭️  Skipped: {skipped}")
    print(f"   ❌ Errors: {errors}")
    print(f"   📁 Total: {len(FILES_TO_MIGRATE)}")

if __name__ == "__main__":
    main()
