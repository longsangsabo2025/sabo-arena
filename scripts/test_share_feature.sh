#!/usr/bin/env bash

# Test Share Feature End-to-End Script
# This script runs comprehensive tests for the share feature in LeaderboardScreen

echo "🧪 Starting Leaderboard Share Feature End-to-End Tests..."
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Running: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# 1. Unit Tests for ShareService
echo -e "${YELLOW}📋 Phase 1: Unit Tests${NC}"
echo "========================="

run_test "ShareService Unit Tests" "flutter test test/unit/services/share_service_test.dart"

# 2. Widget Tests for LeaderboardScreen
echo -e "${YELLOW}📱 Phase 2: Widget Tests${NC}"
echo "=========================="

run_test "LeaderboardScreen Widget Tests" "flutter test test/widget/leaderboard_screen_test.dart"

# 3. Integration Tests
echo -e "${YELLOW}🔗 Phase 3: Integration Tests${NC}"
echo "=============================="

run_test "Leaderboard Share Integration Tests" "flutter test test/integration/leaderboard_share_test.dart"

# 4. Manual Test Checklist
echo -e "${YELLOW}📝 Phase 4: Manual Test Checklist${NC}"
echo "===================================="

echo "Please manually verify the following:"
echo "1. ✅ Share button is visible in leaderboard app bar"
echo "2. ✅ Share button has tooltip 'Chia sẻ bảng xếp hạng'"
echo "3. ✅ Tapping share button opens system share dialog"
echo "4. ✅ Share content includes tournament name, club name, and player count"
echo "5. ✅ Share works on all tabs (ELO, Wins, Tournaments, SPA Points)"
echo "6. ✅ Share works with all rank filters (All, K, I, H, G, F, E)"
echo "7. ✅ Share URL format: https://saboarena.com/leaderboard/[tournament_id]"
echo "8. ✅ Share text includes proper hashtags: #SABOArena #Billiards #Leaderboard"
echo "9. ✅ No errors occur when sharing with empty leaderboard"
echo "10. ✅ Share works after pull-to-refresh"

# 5. Performance and Edge Case Tests
echo -e "${YELLOW}⚡ Phase 5: Performance & Edge Cases${NC}"
echo "===================================="

echo "Testing edge cases..."

# Test with large leaderboard data
run_test "Large Dataset Performance" "flutter test test/widget/leaderboard_screen_test.dart --plain-name='Share works with large dataset'"

# Test network failure scenarios
run_test "Network Failure Handling" "flutter test test/widget/leaderboard_screen_test.dart --plain-name='Error handling when share fails'"

# 6. Device-specific Tests (if running on real device)
echo -e "${YELLOW}📱 Phase 6: Device-Specific Tests${NC}"
echo "=================================="

echo "If running on real device, please test:"
echo "- Share to WhatsApp"
echo "- Share to Telegram"
echo "- Share to Facebook"
echo "- Share to Email"
echo "- Share to SMS"
echo "- Copy to clipboard"

# 7. Test Results Summary
echo -e "${YELLOW}📊 Test Results Summary${NC}"
echo "======================="

echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Share feature is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review and fix issues.${NC}"
    exit 1
fi

# 8. Additional Validation Commands
echo -e "${YELLOW}🔍 Additional Validation${NC}"
echo "========================"

echo "Run these commands for additional validation:"
echo "1. flutter analyze (check for static analysis issues)"
echo "2. flutter test --coverage (generate coverage report)"
echo "3. flutter drive --target=test_driver/app.dart (run driver tests)"

# 9. Code Quality Checks
echo -e "${YELLOW}📏 Code Quality Checks${NC}"
echo "======================"

echo "Checking code quality..."

# Check if share_plus dependency is properly added
if grep -q "share_plus:" pubspec.yaml; then
    echo "✅ share_plus dependency found in pubspec.yaml"
else
    echo "❌ share_plus dependency missing in pubspec.yaml"
fi

# Check if ShareService import exists in LeaderboardScreen
if grep -q "import.*share_service.dart" lib/presentation/leaderboard_screen/leaderboard_screen.dart; then
    echo "✅ ShareService properly imported in LeaderboardScreen"
else
    echo "❌ ShareService import missing in LeaderboardScreen"
fi

# Check if share button exists in LeaderboardScreen
if grep -q "Icons.share" lib/presentation/leaderboard_screen/leaderboard_screen.dart; then
    echo "✅ Share button found in LeaderboardScreen"
else
    echo "❌ Share button missing in LeaderboardScreen"
fi

echo ""
echo -e "${BLUE}🏁 Share Feature End-to-End Testing Complete!${NC}"
echo "==============================================="