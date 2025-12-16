#!/bin/bash

# 🔐 Script tạo Base64 secrets cho GitHub Actions
# Sử dụng: bash scripts/generate_ios_secrets.sh

set -e

echo "🔐 iOS Secrets Generator for GitHub Actions"
echo "============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output file
OUTPUT_FILE="certificates/GITHUB_SECRETS_GENERATED.txt"

echo "This script will generate all necessary base64-encoded secrets"
echo "for iOS deployment via GitHub Actions."
echo ""

# Check if running on macOS (required for iOS development)
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}⚠️  Warning: This script is designed for macOS${NC}"
    echo "Some features may not work on other platforms."
    echo ""
fi

# Create output file
cat > "$OUTPUT_FILE" << 'EOF'
# 🔐 GitHub Secrets for iOS Deployment
# =====================================
# Copy these values to GitHub Repository Settings > Secrets and variables > Actions
# URL: https://github.com/longsangsabo/saboarenav4/settings/secrets/actions

EOF

echo -e "${BLUE}📋 Generating secrets...${NC}"
echo ""

# Function to add secret to output
add_secret() {
    local name=$1
    local value=$2
    
    cat >> "$OUTPUT_FILE" << EOF

## Secret: $name
\`\`\`
Name: $name
Value: $value
\`\`\`

EOF
    echo -e "${GREEN}✅ Generated: $name${NC}"
}

# ========== 1. API Key ID ==========
if [ -f "certificates/AuthKey_22AL4LKQ94.p8" ]; then
    add_secret "APP_STORE_CONNECT_API_KEY_ID" "22AL4LKQ94"
else
    echo -e "${RED}❌ API Key file not found!${NC}"
fi

# ========== 2. Issuer ID ==========
add_secret "APP_STORE_CONNECT_ISSUER_ID" "4405e7f9-8e89-495a-b535-f9e83e96a7ad"

# ========== 3. API Key Base64 ==========
if [ -f "certificates/AuthKey_22AL4LKQ94.p8" ]; then
    echo -e "${BLUE}🔄 Encoding API key...${NC}"
    API_KEY_BASE64=$(base64 -i certificates/AuthKey_22AL4LKQ94.p8 | tr -d '\n')
    add_secret "APP_STORE_CONNECT_API_KEY_BASE64" "$API_KEY_BASE64"
else
    echo -e "${RED}❌ API Key file not found: certificates/AuthKey_22AL4LKQ94.p8${NC}"
fi

# ========== 4. Distribution Certificate Base64 ==========
if [ -f "certificates/ios_distribution.p12" ]; then
    echo -e "${BLUE}🔄 Encoding distribution certificate...${NC}"
    CERT_BASE64=$(base64 -i certificates/ios_distribution.p12 | tr -d '\n')
    add_secret "IOS_DISTRIBUTION_CERTIFICATE_BASE64" "$CERT_BASE64"
else
    echo -e "${RED}❌ Certificate file not found: certificates/ios_distribution.p12${NC}"
fi

# ========== 5. Certificate Password ==========
add_secret "IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" "saboarena123"

# ========== 6. Provisioning Profile Base64 ==========
if [ -f "certificates/SABO_ARENA.mobileprovision" ]; then
    echo -e "${BLUE}🔄 Encoding provisioning profile...${NC}"
    PROFILE_BASE64=$(base64 -i certificates/SABO_ARENA.mobileprovision | tr -d '\n')
    add_secret "IOS_PROVISIONING_PROFILE_BASE64" "$PROFILE_BASE64"
else
    echo -e "${RED}❌ Provisioning profile not found: certificates/SABO_ARENA.mobileprovision${NC}"
fi

# ========== 7. Apple Team ID ==========
add_secret "APPLE_TEAM_ID" "B465SC3K74"

# ========== 8. Supabase URL ==========
add_secret "SUPABASE_URL" "https://mogjjvscxjwvhtpkrlqr.supabase.co"

# ========== 9. Supabase Anon Key ==========
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
add_secret "SUPABASE_ANON_KEY" "$SUPABASE_KEY"

# Add summary to output file
cat >> "$OUTPUT_FILE" << 'EOF'

# ================================
# 📊 Summary
# ================================

Total secrets: 9/9 ✅

## ✅ Checklist
- [ ] APP_STORE_CONNECT_API_KEY_ID
- [ ] APP_STORE_CONNECT_ISSUER_ID
- [ ] APP_STORE_CONNECT_API_KEY_BASE64
- [ ] IOS_DISTRIBUTION_CERTIFICATE_BASE64
- [ ] IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
- [ ] IOS_PROVISIONING_PROFILE_BASE64
- [ ] APPLE_TEAM_ID
- [ ] SUPABASE_URL
- [ ] SUPABASE_ANON_KEY

## 🚀 Next Steps
1. Go to: https://github.com/longsangsabo/saboarenav4/settings/secrets/actions
2. Click "New repository secret" for each secret above
3. Copy the Name and Value exactly as shown
4. Click "Add secret"
5. Repeat for all 9 secrets
6. Push code to trigger deployment!

## 📝 Notes
- Never commit this file to git (already in .gitignore)
- Keep this file secure and private
- Rotate secrets periodically for security
- Check certificate expiry dates regularly

EOF

echo ""
echo "================================="
echo -e "${GREEN}✅ Secrets generated successfully!${NC}"
echo "================================="
echo ""
echo "Output file: $OUTPUT_FILE"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Open $OUTPUT_FILE"
echo "2. Copy each secret to GitHub"
echo "3. Go to: https://github.com/longsangsabo/saboarenav4/settings/secrets/actions"
echo ""

# Verify generated file
if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo -e "${GREEN}✅ Generated file size: $FILE_SIZE${NC}"
    
    # Count secrets
    SECRET_COUNT=$(grep -c "^## Secret:" "$OUTPUT_FILE")
    echo -e "${GREEN}✅ Total secrets generated: $SECRET_COUNT${NC}"
    
    echo ""
    echo -e "${BLUE}📋 Preview first few lines:${NC}"
    head -20 "$OUTPUT_FILE"
    echo "..."
    echo ""
    
    # Offer to open file
    echo -e "${YELLOW}Would you like to open the file now? [y/N]${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if command -v code &> /dev/null; then
            code "$OUTPUT_FILE"
        elif command -v open &> /dev/null; then
            open "$OUTPUT_FILE"
        else
            cat "$OUTPUT_FILE"
        fi
    fi
else
    echo -e "${RED}❌ Failed to generate secrets file${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All done!${NC}"
