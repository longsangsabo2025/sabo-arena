#!/usr/bin/env python3
"""
Facebook Login Configuration Verification Script
Verifies all Facebook configurations across iOS, Android, and Flutter code
"""

import re
import json
from pathlib import Path
from typing import Dict, List, Tuple

class Color:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

class FacebookConfigVerifier:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.success: List[str] = []
        
        # Expected Facebook credentials (from current config)
        self.facebook_app_id = "4352116018356819"
        self.facebook_client_token = "c75c57e0b7c0c830e8a1e4cd5b4a73bd"
        self.facebook_url_scheme = f"fb{self.facebook_app_id}"
        
    def print_header(self, title: str):
        print(f"\n{Color.BOLD}{Color.BLUE}{'='*60}{Color.END}")
        print(f"{Color.BOLD}{Color.BLUE}{title:^60}{Color.END}")
        print(f"{Color.BOLD}{Color.BLUE}{'='*60}{Color.END}\n")
        
    def check_ios_info_plist(self) -> bool:
        """Check iOS Info.plist for Facebook configuration"""
        print(f"{Color.BOLD}🍎 Checking iOS Info.plist...{Color.END}")
        
        plist_path = self.project_root / "ios" / "Runner" / "Info.plist"
        if not plist_path.exists():
            self.errors.append(f"❌ Info.plist not found: {plist_path}")
            return False
            
        content = plist_path.read_text(encoding='utf-8')
        
        checks = [
            (f"<string>{self.facebook_app_id}</string>", "Facebook App ID"),
            (f"<string>{self.facebook_url_scheme}</string>", "Facebook URL Scheme"),
            ("<key>FacebookAppID</key>", "FacebookAppID key"),
            ("<key>FacebookClientToken</key>", "FacebookClientToken key"),
            (f"<string>{self.facebook_client_token}</string>", "Facebook Client Token"),
            ("<string>fbapi</string>", "LSApplicationQueriesSchemes - fbapi"),
            ("<string>fbauth2</string>", "LSApplicationQueriesSchemes - fbauth2"),
        ]
        
        all_good = True
        for pattern, name in checks:
            if pattern in content:
                self.success.append(f"  ✅ {name}")
            else:
                self.errors.append(f"  ❌ Missing: {name}")
                all_good = False
                
        return all_good
        
    def check_ios_appdelegate(self) -> bool:
        """Check iOS AppDelegate.swift for Facebook SDK initialization"""
        print(f"\n{Color.BOLD}📱 Checking iOS AppDelegate.swift...{Color.END}")
        
        appdelegate_path = self.project_root / "ios" / "Runner" / "AppDelegate.swift"
        if not appdelegate_path.exists():
            self.errors.append(f"❌ AppDelegate.swift not found")
            return False
            
        content = appdelegate_path.read_text(encoding='utf-8')
        
        checks = [
            ("import FBSDKCoreKit", "Import FBSDKCoreKit"),
            ("ApplicationDelegate.shared.application", "Facebook SDK initialization"),
            ("didFinishLaunchingWithOptions", "didFinishLaunchingWithOptions method"),
        ]
        
        all_good = True
        for pattern, name in checks:
            if pattern in content:
                self.success.append(f"  ✅ {name}")
            else:
                self.errors.append(f"  ❌ Missing: {name}")
                all_good = False
                
        return all_good
        
    def check_ios_podfile(self) -> bool:
        """Check iOS Podfile for Facebook SDK version constraint"""
        print(f"\n{Color.BOLD}📦 Checking iOS Podfile...{Color.END}")
        
        podfile_path = self.project_root / "ios" / "Podfile"
        if not podfile_path.exists():
            self.errors.append(f"❌ Podfile not found")
            return False
            
        content = podfile_path.read_text(encoding='utf-8')
        
        if "pod 'FBSDKCoreKit'" in content and "pod 'FBSDKLoginKit'" in content:
            self.success.append(f"  ✅ Facebook SDK pods configured")
            if "17.0" in content:
                self.success.append(f"  ✅ Facebook SDK v17 constraint (flutter_facebook_auth compatible)")
            else:
                self.warnings.append(f"  ⚠️  Facebook SDK version not explicitly set to v17")
            return True
        else:
            self.errors.append(f"  ❌ Facebook SDK pods not found in Podfile")
            return False
            
    def check_android_manifest(self) -> bool:
        """Check Android AndroidManifest.xml for Facebook configuration"""
        print(f"\n{Color.BOLD}🤖 Checking Android AndroidManifest.xml...{Color.END}")
        
        manifest_path = self.project_root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
        if not manifest_path.exists():
            self.errors.append(f"❌ AndroidManifest.xml not found")
            return False
            
        content = manifest_path.read_text(encoding='utf-8')
        
        checks = [
            ('android:name="com.facebook.sdk.ApplicationId"', "Facebook App ID meta-data"),
            ('android:name="com.facebook.sdk.ClientToken"', "Facebook Client Token meta-data"),
            ('@string/facebook_app_id', "Reference to strings.xml"),
            ('@string/facebook_client_token', "Reference to strings.xml"),
        ]
        
        all_good = True
        for pattern, name in checks:
            if pattern in content:
                self.success.append(f"  ✅ {name}")
            else:
                self.errors.append(f"  ❌ Missing: {name}")
                all_good = False
                
        return all_good
        
    def check_android_strings(self) -> bool:
        """Check Android strings.xml for Facebook credentials"""
        print(f"\n{Color.BOLD}📝 Checking Android strings.xml...{Color.END}")
        
        strings_path = self.project_root / "android" / "app" / "src" / "main" / "res" / "values" / "strings.xml"
        if not strings_path.exists():
            self.errors.append(f"❌ strings.xml not found")
            return False
            
        content = strings_path.read_text(encoding='utf-8')
        
        # Check for App ID
        if f"<string name=\"facebook_app_id\">{self.facebook_app_id}</string>" in content:
            self.success.append(f"  ✅ Facebook App ID: {self.facebook_app_id}")
        else:
            self.errors.append(f"  ❌ Facebook App ID missing or incorrect")
            return False
            
        # Check for Client Token
        if '<string name="facebook_client_token">' in content:
            self.success.append(f"  ✅ Facebook Client Token present")
        else:
            self.errors.append(f"  ❌ Facebook Client Token missing")
            return False
            
        return True
        
    def check_pubspec_yaml(self) -> bool:
        """Check pubspec.yaml for flutter_facebook_auth dependency"""
        print(f"\n{Color.BOLD}📦 Checking pubspec.yaml...{Color.END}")
        
        pubspec_path = self.project_root / "pubspec.yaml"
        if not pubspec_path.exists():
            self.errors.append(f"❌ pubspec.yaml not found")
            return False
            
        content = pubspec_path.read_text(encoding='utf-8')
        
        if "flutter_facebook_auth:" in content:
            # Extract version
            match = re.search(r'flutter_facebook_auth:\s*\^?(\d+\.\d+\.\d+)', content)
            if match:
                version = match.group(1)
                self.success.append(f"  ✅ flutter_facebook_auth: ^{version}")
                
                # Check if version is compatible (should be 7.1.x for FB SDK v17)
                major, minor, _ = version.split('.')
                if major == '7' and minor == '1':
                    self.success.append(f"  ✅ Version compatible with Facebook SDK v17")
                else:
                    self.warnings.append(f"  ⚠️  Version {version} may not be compatible with FB SDK v17")
            return True
        else:
            self.errors.append(f"  ❌ flutter_facebook_auth not found in dependencies")
            return False
            
    def check_service_implementation(self) -> bool:
        """Check service implementation for Facebook login"""
        print(f"\n{Color.BOLD}🔧 Checking Social Auth Service...{Color.END}")
        
        service_path = self.project_root / "lib" / "services" / "social_auth_service.dart"
        if not service_path.exists():
            self.errors.append(f"❌ social_auth_service.dart not found")
            return False
            
        content = service_path.read_text(encoding='utf-8')
        
        checks = [
            ("import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'", "Import flutter_facebook_auth"),
            ("signInWithFacebook", "signInWithFacebook method"),
            ("FacebookAuth.instance.login", "Facebook login call"),
            ("LoginBehavior", "LoginBehavior configuration"),
            ("signInWithIdToken", "Supabase integration"),
            ("OAuthProvider.facebook", "OAuth provider"),
        ]
        
        all_good = True
        for pattern, name in checks:
            if pattern in content:
                self.success.append(f"  ✅ {name}")
            else:
                self.errors.append(f"  ❌ Missing: {name}")
                all_good = False
                
        return all_good
        
    def print_summary(self):
        """Print verification summary"""
        self.print_header("VERIFICATION SUMMARY")
        
        if self.success:
            print(f"{Color.GREEN}{Color.BOLD}✅ PASSED CHECKS ({len(self.success)}):{Color.END}")
            for item in self.success:
                print(f"{Color.GREEN}{item}{Color.END}")
                
        if self.warnings:
            print(f"\n{Color.YELLOW}{Color.BOLD}⚠️  WARNINGS ({len(self.warnings)}):{Color.END}")
            for item in self.warnings:
                print(f"{Color.YELLOW}{item}{Color.END}")
                
        if self.errors:
            print(f"\n{Color.RED}{Color.BOLD}❌ ERRORS ({len(self.errors)}):{Color.END}")
            for item in self.errors:
                print(f"{Color.RED}{item}{Color.END}")
                
        print(f"\n{Color.BOLD}{'='*60}{Color.END}")
        
        if not self.errors:
            print(f"{Color.GREEN}{Color.BOLD}🎉 ALL CHECKS PASSED! Facebook Login is properly configured.{Color.END}")
            return True
        else:
            print(f"{Color.RED}{Color.BOLD}❌ {len(self.errors)} error(s) found. Please fix them before deploying.{Color.END}")
            return False
            
    def run_all_checks(self) -> bool:
        """Run all verification checks"""
        self.print_header("FACEBOOK LOGIN CONFIGURATION VERIFICATION")
        
        print(f"{Color.BOLD}Configuration Details:{Color.END}")
        print(f"  Facebook App ID: {Color.BLUE}{self.facebook_app_id}{Color.END}")
        print(f"  URL Scheme: {Color.BLUE}{self.facebook_url_scheme}{Color.END}")
        
        checks = [
            self.check_ios_info_plist,
            self.check_ios_appdelegate,
            self.check_ios_podfile,
            self.check_android_manifest,
            self.check_android_strings,
            self.check_pubspec_yaml,
            self.check_service_implementation,
        ]
        
        all_passed = all(check() for check in checks)
        
        self.print_summary()
        return all_passed

def main():
    verifier = FacebookConfigVerifier()
    success = verifier.run_all_checks()
    
    if not success:
        print(f"\n{Color.YELLOW}💡 Next Steps:{Color.END}")
        print(f"  1. Fix the errors listed above")
        print(f"  2. Verify Facebook App settings at https://developers.facebook.com")
        print(f"  3. Re-run this script to verify fixes")
        print(f"  4. Test on physical iOS/Android devices")
        exit(1)
    else:
        print(f"\n{Color.GREEN}✅ Ready to deploy! Remember to test on physical devices.{Color.END}")
        exit(0)

if __name__ == "__main__":
    main()
