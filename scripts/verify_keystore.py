#!/usr/bin/env python3
"""
SABO Arena - Keystore Verification Script
==========================================
Verifies keystore SHA1 fingerprint and provides upload instructions.
"""

import subprocess
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
    """Print formatted header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'=' * 60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 60}{Colors.END}\n")

def print_success(text: str):
    """Print success message"""
    print(f"{Colors.GREEN}✅ {text}{Colors.END}")

def print_warning(text: str):
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.END}")

def print_error(text: str):
    """Print error message"""
    print(f"{Colors.RED}❌ {text}{Colors.END}")

def print_info(text: str):
    """Print info message"""
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.END}")

def get_sha1_fingerprint(keystore_path: Path, keystore_password: str, key_alias: str) -> str:
    """Get SHA1 fingerprint from keystore"""
    try:
        # Find keytool executable
        keytool_paths = [
            r"C:\Program Files\Java\jdk-17\bin\keytool.exe",
            r"C:\Program Files\Java\jdk-11\bin\keytool.exe",
            r"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
        ]
        
        keytool_exe = None
        for path in keytool_paths:
            if Path(path).exists():
                keytool_exe = path
                break
        
        if not keytool_exe:
            print_error("Không tìm thấy keytool.exe!")
            return None
        
        # Run keytool command
        cmd = [
            keytool_exe,
            "-list",
            "-v",
            "-keystore", str(keystore_path),
            "-alias", key_alias,
            "-storepass", keystore_password
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
        
        if result.returncode != 0:
            print_error(f"Lỗi chạy keytool: {result.stderr}")
            return None
        
        # Extract SHA1 from output
        for line in result.stdout.split('\n'):
            if 'SHA1:' in line:
                sha1 = line.split('SHA1:')[1].strip()
                return sha1
        
        return None
        
    except Exception as e:
        print_error(f"Lỗi: {e}")
        return None

def main():
    """Main verification function"""
    print_header("🔐 SABO Arena - Keystore Verification")
    
    # Paths
    project_root = Path(__file__).parent.parent
    keystore_path = project_root / "android" / "app" / "sabo-arena-release-key.keystore"
    aab_path = project_root / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
    
    # Keystore config
    keystore_password = "Acookingoil123"
    key_alias = "sabo-arena"
    
    # Expected SHA1 from Google Play Console (if app was uploaded before)
    expected_sha1 = "EB:A5:40:B6:50:73:35:5C:F9:40:02:44:E9:9F:35:9E:1E:B6:1E:F7"
    
    # Step 1: Verify keystore exists
    print_info(f"Kiểm tra keystore: {keystore_path}")
    if not keystore_path.exists():
        print_error(f"Keystore không tồn tại: {keystore_path}")
        sys.exit(1)
    print_success(f"Keystore found: {keystore_path.name}")
    
    # Step 2: Get SHA1 fingerprint
    print_info("Đang lấy SHA1 fingerprint...")
    current_sha1 = get_sha1_fingerprint(keystore_path, keystore_password, key_alias)
    
    if not current_sha1:
        print_error("Không thể lấy SHA1 fingerprint!")
        sys.exit(1)
    
    print_success(f"Current SHA1: {current_sha1}")
    
    # Step 3: Compare with expected SHA1
    print("\n" + "="*60)
    if current_sha1 == expected_sha1:
        print_success("SHA1 MATCH! Keystore đúng với Google Play Console!")
        status = "MATCH"
    else:
        print_warning("SHA1 KHÁC với Google Play Console!")
        print_info(f"Expected: {expected_sha1}")
        print_info(f"Current:  {current_sha1}")
        print()
        print_warning("Điều này có nghĩa:")
        print("  1. Nếu app CHƯA được upload → Sử dụng keystore hiện tại")
        print("  2. Nếu app ĐÃ được upload → Cần keystore cũ hoặc reset app")
        status = "MISMATCH"
    
    # Step 4: Check AAB file
    print("\n" + "="*60)
    print_info(f"Kiểm tra AAB file: {aab_path}")
    if aab_path.exists():
        aab_size_mb = aab_path.stat().st_size / (1024 * 1024)
        print_success(f"AAB file found: {aab_size_mb:.1f} MB")
        
        # Provide upload instructions
        print_header("📤 HƯỚNG DẪN UPLOAD LÊN GOOGLE PLAY")
        print("1. Truy cập: https://play.google.com/console")
        print("2. Chọn app 'SABO Arena'")
        print("3. Production → Create new release")
        print("4. Upload AAB file:")
        print(f"   {Colors.BOLD}{aab_path}{Colors.END}")
        print("5. Nếu gặp lỗi SHA1:")
        print("   - Option A: Tạo app mới trên Google Play Console")
        print("   - Option B: Tìm keystore cũ (nếu app đã upload trước)")
        print("   - Option C: Reset signing key (mất user hiện tại)")
        
    else:
        print_warning(f"AAB file chưa được build!")
        print_info("Chạy: flutter build appbundle --release")
    
    # Step 5: Summary
    print_header("📊 TÓM TẮT")
    print(f"Keystore: {Colors.GREEN}✅ Valid{Colors.END}")
    print(f"SHA1: {Colors.YELLOW if status == 'MISMATCH' else Colors.GREEN}{current_sha1}{Colors.END}")
    print(f"Status: {Colors.YELLOW if status == 'MISMATCH' else Colors.GREEN}{status}{Colors.END}")
    print(f"AAB: {Colors.GREEN if aab_path.exists() else Colors.RED}{'✅ Ready' if aab_path.exists() else '❌ Not built'}{Colors.END}")
    
    print()
    if status == "MATCH":
        print_success("Sẵn sàng upload lên Google Play Console!")
    else:
        print_warning("Cần xác nhận: App đã được upload trước đó chưa?")

if __name__ == "__main__":
    main()
