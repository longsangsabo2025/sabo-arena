#!/bin/bash

# Build iOS for App Store
# Run this script on macOS only

echo "🚀 Building iOS App for App Store..."

# Clean previous builds
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ

echo "✅ iOS build completed!"
echo "📱 Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Select 'Any iOS Device' as target"
echo "3. Product > Archive"
echo "4. Upload to App Store Connect"

# Open Xcode workspace
open ios/Runner.xcworkspace