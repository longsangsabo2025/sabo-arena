#!/bin/bash

# 🔐 Script kiểm tra và validate iOS Secrets cho GitHub Actions
# Sử dụng: bash scripts/validate_ios_secrets.sh

set -e

echo "🔍 iOS Secrets Validation Script"
echo "================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0

check_secret() {
    local name=$1
    local required=$2
    TOTAL=$((TOTAL + 1))
    
    if [ -z "$required" ]; then
        echo -e "${RED}❌ $name: MISSING${NC}"
        FAILED=$((FAILED + 1))
        return 1
    else
        echo -e "${GREEN}✅ $name: OK${NC}"
        PASSED=$((PASSED + 1))
        return 0
    fi
}

check_file() {
    local name=$1
    local file=$2
    TOTAL=$((TOTAL + 1))
    
    if [ -f "$file" ]; then
        local size=$(du -h "$file" | cut -f1)
        echo -e "${GREEN}✅ $name: OK ($size)${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ $name: NOT FOUND${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "📋 Checking Certificate Files..."
echo "-----------------------------------"
check_file "Distribution Certificate (.p12)" "certificates/ios_distribution.p12"
check_file "Distribution Certificate (.cer)" "certificates/ios_distribution.cer"
check_file "Private Key (.key)" "certificates/ios_distribution.key"
check_file "Provisioning Profile" "certificates/SABO_ARENA.mobileprovision"
check_file "API Key (.p8)" "certificates/AuthKey_22AL4LKQ94.p8"
echo ""

echo "🔑 Validating Certificate Contents..."
echo "-----------------------------------"

# Check .p12 password
if [ -f "certificates/ios_distribution.p12" ]; then
    if openssl pkcs12 -in certificates/ios_distribution.p12 -noout -passin pass:saboarena123 2>/dev/null; then
        echo -e "${GREEN}✅ Certificate password: CORRECT${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ Certificate password: INCORRECT${NC}"
        FAILED=$((FAILED + 1))
    fi
    TOTAL=$((TOTAL + 1))
fi

# Check certificate expiry
if [ -f "certificates/ios_distribution.cer" ]; then
    EXPIRY=$(openssl x509 -in certificates/ios_distribution.cer -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "$EXPIRY" ]; then
        echo -e "${GREEN}✅ Certificate expiry: $EXPIRY${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ Cannot read certificate expiry${NC}"
        FAILED=$((FAILED + 1))
    fi
    TOTAL=$((TOTAL + 1))
fi

# Check provisioning profile expiry
if [ -f "certificates/SABO_ARENA.mobileprovision" ]; then
    EXPIRY=$(grep -a ExpirationDate -A1 certificates/SABO_ARENA.mobileprovision | tail -1 | sed 's/.*<date>\(.*\)<\/date>.*/\1/')
    if [ -n "$EXPIRY" ]; then
        echo -e "${GREEN}✅ Provisioning profile expiry: $EXPIRY${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠️  Cannot read provisioning profile expiry${NC}"
    fi
    TOTAL=$((TOTAL + 1))
fi

echo ""
echo "🔐 Checking Base64 Encoding..."
echo "-----------------------------------"

# Check if base64 encoded files exist
if [ -f "certificates/GITHUB_SECRETS_COMPLETE.md" ]; then
    echo -e "${GREEN}✅ GITHUB_SECRETS_COMPLETE.md: EXISTS${NC}"
    PASSED=$((PASSED + 1))
    
    # Verify base64 content length
    CERT_BASE64=$(grep -A1 "IOS_DISTRIBUTION_CERTIFICATE_BASE64" certificates/GITHUB_SECRETS_COMPLETE.md | tail -1 | wc -c)
    PROFILE_BASE64=$(grep -A1 "IOS_PROVISIONING_PROFILE_BASE64" certificates/GITHUB_SECRETS_COMPLETE.md | tail -1 | wc -c)
    API_BASE64=$(grep -A1 "APP_STORE_CONNECT_API_KEY_BASE64" certificates/GITHUB_SECRETS_COMPLETE.md | tail -1 | wc -c)
    
    if [ $CERT_BASE64 -gt 100 ]; then
        echo -e "${GREEN}✅ Certificate base64: OK (${CERT_BASE64} chars)${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ Certificate base64: TOO SHORT${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    if [ $PROFILE_BASE64 -gt 100 ]; then
        echo -e "${GREEN}✅ Provisioning profile base64: OK (${PROFILE_BASE64} chars)${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ Provisioning profile base64: TOO SHORT${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    if [ $API_BASE64 -gt 50 ]; then
        echo -e "${GREEN}✅ API key base64: OK (${API_BASE64} chars)${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ API key base64: TOO SHORT${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    TOTAL=$((TOTAL + 4))
else
    echo -e "${RED}❌ GITHUB_SECRETS_COMPLETE.md: NOT FOUND${NC}"
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
fi

echo ""
echo "📱 Checking iOS Project Configuration..."
echo "-----------------------------------"

# Check Bundle ID
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    BUNDLE_ID=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*' ios/Runner.xcodeproj/project.pbxproj | head -1 | cut -d' ' -f3)
    if [ -n "$BUNDLE_ID" ]; then
        echo -e "${GREEN}✅ Bundle ID: $BUNDLE_ID${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ Bundle ID: NOT FOUND${NC}"
        FAILED=$((FAILED + 1))
    fi
    TOTAL=$((TOTAL + 1))
fi

# Check Team ID
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    TEAM_ID=$(grep -o 'DEVELOPMENT_TEAM = [^;]*' ios/Runner.xcodeproj/project.pbxproj | head -1 | cut -d' ' -f3)
    if [ "$TEAM_ID" == "B465SC3K74" ]; then
        echo -e "${GREEN}✅ Team ID: $TEAM_ID${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠️  Team ID: $TEAM_ID (Expected: B465SC3K74)${NC}"
    fi
    TOTAL=$((TOTAL + 1))
fi

echo ""
echo "🔧 Checking GitHub Workflow..."
echo "-----------------------------------"

# Check if workflow files exist
check_file "iOS Deploy Workflow" ".github/workflows/ios-deploy.yml"
check_file "iOS AppStore Deploy Workflow" ".github/workflows/ios-appstore-deploy.yml"

echo ""
echo "================================="
echo "📊 Validation Summary"
echo "================================="
echo -e "Total checks: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: ${FAILED}${NC}"
else
    echo -e "${GREEN}Failed: ${FAILED}${NC}"
fi
echo ""

# Calculate percentage
PERCENTAGE=$((PASSED * 100 / TOTAL))

if [ $PERCENTAGE -eq 100 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for deployment! 🚀${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Go to https://github.com/longsangsabo/saboarenav4/settings/secrets/actions"
    echo "2. Add all secrets from certificates/GITHUB_SECRETS_COMPLETE.md"
    echo "3. Push code to main branch to trigger deployment"
    exit 0
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "${YELLOW}⚠️  Most checks passed ($PERCENTAGE%). Review warnings above.${NC}"
    exit 0
else
    echo -e "${RED}❌ Multiple checks failed ($PERCENTAGE%). Please fix issues above.${NC}"
    exit 1
fi
