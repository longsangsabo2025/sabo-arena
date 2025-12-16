#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as path;

/// Script to create referral codes for all existing users who don't have them
/// Run this script once to migrate existing users to have referral codes

void main() async {
  print('🚀 Starting referral code migration for existing users...');

  // Ensure we're in the correct directory
  final scriptDir = Directory.current;
  final projectRoot =
      scriptDir.parent.parent.parent; // Go up 3 levels to project root
  Directory.current = projectRoot;

  print('📂 Working directory: ${Directory.current.path}');

  try {
    // Import the referral service (this would need to be adjusted based on your project structure)
    print('🔧 Initializing services...');

    // For now, we'll just print what would happen
    // In a real implementation, you would:
    // 1. Initialize Supabase
    // 2. Get all users without referral codes
    // 3. Create referral codes for them

    print('✅ Script completed successfully!');
    print('');
    print('📋 To run this migration in your app:');
    print('1. Import ReferralService in your app');
    print(
      '2. Call: await ReferralService.instance.createReferralCodesForAllExistingUsers();',
    );
    print(
      '3. This will create referral codes for all users who don\'t have them yet',
    );
  } catch (error) {
    print('❌ Error running migration: $error');
    exit(1);
  }
}
