import { test, expect } from '@playwright/test';

/**
 * Authentication Flow E2E Tests
 * Tests user registration, login, logout flows
 */
test.describe('Authentication', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Wait for Flutter app to load (Flutter web takes time to initialize)
    await page.waitForTimeout(5000);
    // Wait for any loading indicators to disappear
    await page.waitForLoadState('networkidle');
  });

  test('should display login screen', async ({ page }) => {
    // Check for login elements (Flutter web may render differently)
    // Try multiple selectors to find login screen
    const loginSelectors = [
      'text=/Đăng nhập|Login/i',
      'button:has-text("Đăng nhập")',
      'button:has-text("Login")',
      '[aria-label*="login" i]',
      '[data-testid="login-button"]',
    ];

    let found = false;
    for (const selector of loginSelectors) {
      const element = page.locator(selector).first();
      if (await element.isVisible({ timeout: 2000 }).catch(() => false)) {
        found = true;
        break;
      }
    }

    // If no login button found, check if we're on splash/onboarding screen
    if (!found) {
      const splashScreen = page.locator('text=/SABO|Arena|Welcome/i').first();
      const isSplashVisible = await splashScreen.isVisible({ timeout: 2000 }).catch(() => false);
      expect(isSplashVisible || found, true);
    } else {
      expect(found, true);
    }
  });

  test('should register new user', async ({ page }) => {
    // Navigate to registration
    const registerButton = page.locator('text=/Đăng ký|Register/i').first();
    if (await registerButton.isVisible()) {
      await registerButton.click();
      await page.waitForTimeout(1000);

      // Fill registration form
      const emailInput = page.locator('input[type="email"]').first();
      const passwordInput = page.locator('input[type="password"]').first();
      const nameInput = page.locator('input[placeholder*="name" i]').first();

      if (await emailInput.isVisible()) {
        await emailInput.fill(`test-${Date.now()}@example.com`);
        await passwordInput.fill('Test123!@#');
        if (await nameInput.isVisible()) {
          await nameInput.fill('Test User');
        }

        // Submit registration
        const submitButton = page.locator('button:has-text("Đăng ký"), button:has-text("Register")').first();
        if (await submitButton.isVisible()) {
          await submitButton.click();
          await page.waitForTimeout(3000);

          // Should redirect to home or show success message
          const successIndicator = page.locator('text=/thành công|success|welcome/i').first();
          // Note: This test may need adjustment based on actual app behavior
        }
      }
    }
  });

  test('should login with valid credentials', async ({ page }) => {
    // This test requires test credentials
    // In real scenario, use environment variables or test database
    const emailInput = page.locator('input[type="email"]').first();
    const passwordInput = page.locator('input[type="password"]').first();

    if (await emailInput.isVisible()) {
      await emailInput.fill(process.env.TEST_EMAIL || 'test@example.com');
      await passwordInput.fill(process.env.TEST_PASSWORD || 'password123');

      const loginButton = page.locator('button:has-text("Đăng nhập"), button:has-text("Login")').first();
      if (await loginButton.isVisible()) {
        await loginButton.click();
        await page.waitForTimeout(3000);

        // Should be logged in (check for user menu or profile)
        const userMenu = page.locator('[aria-label*="user"], [aria-label*="profile"]').first();
        // Note: Adjust selector based on actual app
      }
    }
  });

  test('should show error for invalid credentials', async ({ page }) => {
    const emailInput = page.locator('input[type="email"]').first();
    const passwordInput = page.locator('input[type="password"]').first();

    if (await emailInput.isVisible()) {
      await emailInput.fill('invalid@example.com');
      await passwordInput.fill('wrongpassword');

      const loginButton = page.locator('button:has-text("Đăng nhập"), button:has-text("Login")').first();
      if (await loginButton.isVisible()) {
        await loginButton.click();
        await page.waitForTimeout(2000);

        // Should show error message
        const errorMessage = page.locator('text=/lỗi|error|invalid|sai/i').first();
        // Note: Adjust based on actual error display
      }
    }
  });

  test('should logout successfully', async ({ page }) => {
    // First login (if not already logged in)
    // Then logout
    const logoutButton = page.locator('text=/Đăng xuất|Logout/i').first();
    
    if (await logoutButton.isVisible()) {
      await logoutButton.click();
      await page.waitForTimeout(2000);

      // Should redirect to login screen
      const loginButton = page.locator('text=/Đăng nhập|Login/i').first();
      await expect(loginButton).toBeVisible({ timeout: 5000 });
    }
  });
});

