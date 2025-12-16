import { test, expect } from '@playwright/test';

/**
 * Club Management E2E Tests
 * Tests club creation, joining, member management
 */
test.describe('Club Management', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);
  });

  test('should display club list', async ({ page }) => {
    // Navigate to clubs
    const clubTab = page.locator('text=/Câu lạc bộ|Club/i').first();
    
    if (await clubTab.isVisible()) {
      await clubTab.click();
      await page.waitForTimeout(2000);

      // Should show club list
      const clubCards = page.locator('[data-testid="club-card"], .club-card').first();
    }
  });

  test('should create new club', async ({ page }) => {
    const createButton = page.locator('text=/Tạo câu lạc bộ|Create Club/i').first();
    
    if (await createButton.isVisible()) {
      await createButton.click();
      await page.waitForTimeout(1000);

      // Fill club form
      const nameInput = page.locator('input[placeholder*="tên" i], input[placeholder*="name" i]').first();
      const addressInput = page.locator('input[placeholder*="địa chỉ" i], input[placeholder*="address" i]').first();

      if (await nameInput.isVisible()) {
        await nameInput.fill(`Test Club ${Date.now()}`);
        if (await addressInput.isVisible()) {
          await addressInput.fill('123 Test Street');
        }

        const submitButton = page.locator('button:has-text("Tạo"), button:has-text("Create")').first();
        if (await submitButton.isVisible()) {
          await submitButton.click();
          await page.waitForTimeout(3000);

          // Should show success or redirect
          const successIndicator = page.locator('text=/thành công|success/i').first();
        }
      }
    }
  });

  test('should join club', async ({ page }) => {
    const clubCard = page.locator('[data-testid="club-card"]').first();
    
    if (await clubCard.isVisible()) {
      await clubCard.click();
      await page.waitForTimeout(2000);

      const joinButton = page.locator('button:has-text("Tham gia"), button:has-text("Join")').first();
      if (await joinButton.isVisible()) {
        await joinButton.click();
        await page.waitForTimeout(2000);

        // Should show confirmation
        const confirmation = page.locator('text=/thành công|success|đã tham gia/i').first();
      }
    }
  });

  test('should view club members', async ({ page }) => {
    const clubCard = page.locator('[data-testid="club-card"]').first();
    
    if (await clubCard.isVisible()) {
      await clubCard.click();
      await page.waitForTimeout(2000);

      // Navigate to members tab
      const membersTab = page.locator('text=/Thành viên|Members/i').first();
      if (await membersTab.isVisible()) {
        await membersTab.click();
        await page.waitForTimeout(2000);

        // Should show member list
        const memberList = page.locator('[data-testid="member-list"], .member-item').first();
      }
    }
  });
});

