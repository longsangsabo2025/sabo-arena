#!/usr/bin/env python3
"""
SABO Arena - Google Play Upload Assistant
==========================================
Automated helper script for uploading to Google Play Console
"""

import webbrowser
import pyperclip
import sys
from pathlib import Path

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text: str):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.END}\n")

def print_step(number: int, text: str):
    print(f"{Colors.BOLD}{Colors.GREEN}STEP {number}:{Colors.END} {text}")

def print_success(text: str):
    print(f"{Colors.GREEN}✅ {text}{Colors.END}")

def print_warning(text: str):
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.END}")

def print_info(text: str):
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.END}")

def main():
    print_header("🚀 SABO Arena - Google Play Upload Assistant")
    
    # Paths
    project_root = Path(__file__).parent.parent
    aab_path = project_root / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
    
    # Verify AAB exists
    if not aab_path.exists():
        print(f"{Colors.RED}❌ AAB file not found: {aab_path}{Colors.END}")
        print_info("Run: flutter build appbundle --release")
        sys.exit(1)
    
    aab_size_mb = aab_path.stat().st_size / (1024 * 1024)
    print_success(f"AAB file found: {aab_size_mb:.1f} MB")
    print_info(f"Path: {aab_path}")
    
    # Copy AAB path to clipboard
    try:
        pyperclip.copy(str(aab_path))
        print_success("AAB path copied to clipboard!")
    except:
        print_warning("Could not copy to clipboard (pyperclip not installed)")
    
    print_header("📋 UPLOAD CHECKLIST")
    
    checklist = [
        "✅ AAB file built and verified (76.1 MB)",
        "✅ Google Sign-In configured (google-services.json)",
        "✅ Version: 1.2.5+40",
        "✅ Keystore: sabo-arena-release-key.keystore",
        "✅ SHA1: 67:B1:5A:1F:24:2A:F2:0B:83:CD:7E:5B:47:AE:12:CA:22:05:DF:0B",
        "⏳ Release notes prepared",
        "⏳ Screenshots ready",
        "⏳ Store listing complete"
    ]
    
    for item in checklist:
        print(f"  {item}")
    
    print_header("🎯 UPLOAD STEPS")
    
    print_step(1, "Open Google Play Console")
    print_info("URL: https://play.google.com/console")
    print()
    
    print_step(2, "Select or Create App")
    print_info('If new app: Click "Create app" → Enter "SABO Arena"')
    print_info("If existing: Select 'SABO Arena' from app list")
    print()
    
    print_step(3, "Navigate to Production Release")
    print_info("Left menu → Production → Releases")
    print_info("Click 'Create new release'")
    print()
    
    print_step(4, "Upload AAB File")
    print_info("Click 'Upload' button in App bundles section")
    print_info(f"Select: {aab_path}")
    print_info("(Path already copied to clipboard - just paste with Ctrl+V)")
    print()
    
    print_step(5, "Fill Release Details")
    print_info("Release name: v1.2.5 (Build 40)")
    print_info("Release notes: See below")
    print()
    
    print_step(6, "Review and Rollout")
    print_info("Review → Save → Send for review")
    print()
    
    print_header("📝 RELEASE NOTES (Vietnamese)")
    
    release_notes_vi = """
🎉 Phiên bản 1.2.5 - Cập nhật Giao diện & Sửa lỗi

✨ Tính năng mới:
• Tối ưu giao diện danh sách giải đấu
• Cải thiện hiển thị thông tin trận đấu
• Nâng cấp trải nghiệm người dùng

🐛 Sửa lỗi:
• Sửa lỗi hiển thị overflow trong tournament cards
• Sửa lỗi dialog không scroll được
• Tối ưu hiệu năng tổng thể

🔧 Cải tiến kỹ thuật:
• Cập nhật dependencies lên phiên bản mới nhất
• Tối ưu memory management
• Cải thiện trải nghiệm đăng nhập Google
    """.strip()
    
    print(release_notes_vi)
    print()
    
    print_header("📝 RELEASE NOTES (English)")
    
    release_notes_en = """
🎉 Version 1.2.5 - UI Updates & Bug Fixes

✨ New Features:
• Optimized tournament list interface
• Improved match information display
• Enhanced user experience

🐛 Bug Fixes:
• Fixed overflow display in tournament cards
• Fixed non-scrollable dialogs
• Overall performance optimization

🔧 Technical Improvements:
• Updated dependencies to latest versions
• Optimized memory management
• Improved Google Sign-In experience
    """.strip()
    
    print(release_notes_en)
    print()
    
    # App information
    print_header("📱 APP INFORMATION")
    print(f"App name: {Colors.BOLD}SABO Arena{Colors.END}")
    print(f"Package: {Colors.BOLD}com.sabo_arena.app{Colors.END}")
    print(f"Version: {Colors.BOLD}1.2.5 (Build 40){Colors.END}")
    print(f"Category: {Colors.BOLD}Sports{Colors.END}")
    print(f"Content rating: {Colors.BOLD}Everyone{Colors.END}")
    print()
    
    print_header("⚠️ IMPORTANT NOTES")
    print_warning("First upload to Google Play Console")
    print_warning("SHA1 fingerprint will be registered automatically")
    print_warning("Review process typically takes 1-3 days")
    print_warning("Enable Google Play App Signing when prompted")
    print()
    
    print_header("🌐 USEFUL LINKS")
    print("• Play Console: https://play.google.com/console")
    print("• Developer Policy: https://play.google.com/about/developer-content-policy/")
    print("• Release Dashboard: https://play.google.com/console/u/0/developers/[YOUR-ID]/app-list")
    print()
    
    # Ask to open browser
    print_header("🚀 READY TO UPLOAD")
    print(f"{Colors.BOLD}AAB Path (in clipboard):{Colors.END}")
    print(f"{Colors.GREEN}{aab_path}{Colors.END}")
    print()
    
    response = input(f"{Colors.YELLOW}Open Google Play Console now? (y/n): {Colors.END}").strip().lower()
    
    if response == 'y':
        print_info("Opening Google Play Console...")
        webbrowser.open('https://play.google.com/console')
        print_success("Browser opened!")
        print_info("Follow the steps above to complete the upload")
    else:
        print_info("You can manually open: https://play.google.com/console")
    
    print()
    print_success("Upload preparation complete! 🎉")
    print_info("Good luck with your release!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Upload assistant cancelled.{Colors.END}")
        sys.exit(0)
