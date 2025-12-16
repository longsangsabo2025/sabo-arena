# E2E Testing với Playwright - SABO Arena

## 🎯 Mục đích

Test toàn bộ tính năng của SABO Arena trước khi deploy lên App Store, đảm bảo:
- ✅ Tất cả flows hoạt động đúng
- ✅ Performance đạt yêu cầu
- ✅ Không có critical bugs
- ✅ UX/UI responsive trên các devices

## 📋 Test Coverage

### 1. **Authentication** (`auth.spec.ts`)
- ✅ Login flow
- ✅ Registration flow
- ✅ Logout flow
- ✅ Error handling

### 2. **Tournament Flow** (`tournament.spec.ts`)
- ✅ Tournament list display
- ✅ Tournament creation
- ✅ Tournament registration
- ✅ Bracket visualization
- ✅ Match score updates

### 3. **Club Management** (`club.spec.ts`)
- ✅ Club list display
- ✅ Club creation
- ✅ Joining clubs
- ✅ Member management

### 4. **Payment Flow** (`payment.spec.ts`)
- ✅ Tournament entry payment
- ✅ Voucher redemption
- ✅ Payment history

### 5. **Leaderboard** (`leaderboard.spec.ts`)
- ✅ Leaderboard display
- ✅ Rank filtering
- ✅ Share functionality
- ✅ Tab switching

### 6. **Performance** (`performance.spec.ts`)
- ✅ App load time
- ✅ Time to Interactive (TTI)
- ✅ Rapid navigation
- ✅ Image loading

## 🚀 Setup

### 1. Install Dependencies

```bash
cd 02-SABO-ECOSYSTEM/sabo-arena/app
npm install
```

### 2. Install Playwright Browsers

```bash
npx playwright install
```

### 3. Configure Environment Variables

Create `.env` file:
```env
WEB_URL=http://localhost:8080
TEST_EMAIL=test@example.com
TEST_PASSWORD=password123
```

## 🧪 Running Tests

### Run All Tests
```bash
npm run test:e2e
```

### Run Specific Test Suite
```bash
npx playwright test e2e/auth.spec.ts
npx playwright test e2e/tournament.spec.ts
npx playwright test e2e/club.spec.ts
```

### Run Tests in UI Mode
```bash
npx playwright test --ui
```

### Run Tests in Headed Mode
```bash
npx playwright test --headed
```

### Run Tests on Specific Browser
```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit
```

### Run Tests on Mobile
```bash
npx playwright test --project="Mobile Chrome"
npx playwright test --project="Mobile Safari"
```

## 📊 Test Reports

### HTML Report
```bash
npx playwright show-report
```

### JSON Report
```bash
cat test-results/results.json
```

### JUnit Report
```bash
cat test-results/junit.xml
```

## 🔧 Configuration

### Playwright Config (`playwright.config.ts`)
- **Base URL**: `http://localhost:8080` (Flutter web)
- **Browsers**: Chromium, Firefox, WebKit
- **Mobile**: Pixel 5, iPhone 12
- **Retries**: 2 retries in CI
- **Screenshots**: On failure
- **Video**: Retain on failure

### Web Server
Playwright tự động start Flutter web server:
```bash
flutter run -d chrome --web-port=8080
```

## 📝 Test Best Practices

1. **Wait for Flutter App Load**
   - Always wait 2-3 seconds after navigation
   - Use `waitForLoadState('networkidle')` when possible

2. **Selectors**
   - Use text-based selectors (more stable)
   - Add `data-testid` attributes to Flutter widgets for better selectors

3. **Error Handling**
   - Check element visibility before interaction
   - Use conditional checks (`if (await element.isVisible())`)

4. **Performance**
   - Measure load times
   - Check for broken images
   - Monitor network requests

## 🐛 Debugging

### Debug Mode
```bash
npx playwright test --debug
```

### Trace Viewer
```bash
npx playwright show-trace trace.zip
```

### Screenshots
Screenshots are saved in `test-results/` on failure

### Videos
Videos are saved in `test-results/` on failure

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run E2E Tests
  run: |
    npm install
    npx playwright install --with-deps
    npm run test:e2e
```

### Codemagic Integration
Add to `codemagic.yaml`:
```yaml
scripts:
  - name: Run E2E Tests
    script: |
      npm install
      npx playwright install --with-deps
      npm run test:e2e
```

## 📈 Coverage Goals

- ✅ **Critical Flows**: 100% coverage
- ✅ **Authentication**: 100% coverage
- ✅ **Tournament Flow**: 100% coverage
- ✅ **Payment Flow**: 100% coverage
- ✅ **Performance**: All metrics tested

## 🎯 Pre-Deployment Checklist

- [ ] All E2E tests passing
- [ ] Performance metrics within limits
- [ ] No critical bugs found
- [ ] Cross-browser compatibility verified
- [ ] Mobile responsiveness verified
- [ ] Test reports reviewed

---

**Status**: Ready for comprehensive E2E testing before App Store deployment 🚀

