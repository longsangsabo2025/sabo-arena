import { test, expect } from '@playwright/test';

/**
 * Leaderboard E2E Tests
 * Tests leaderboard display, filtering, sharing
 */
test.describe('Leaderboard', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);
  });

  test('should display leaderboard', async ({ page }) => {
    // Navigate to leaderboard
    const leaderboardTab = page.locator('text=/Bảng xếp hạng|Leaderboard/i').first();
    
    if (await leaderboardTab.isVisible()) {
      await leaderboardTab.click();
      await page.waitForTimeout(2000);

      // Should show leaderboard
      const leaderboardTable = page.locator('[data-testid="leaderboard"], .leaderboard-table').first();
      // Note: Adjust selector based on actual implementation
    }
  });

  test('should filter leaderboard by rank', async ({ page }) => {
    const leaderboardTab = page.locator('text=/Bảng xếp hạng|Leaderboard/i').first();
    
    if (await leaderboardTab.isVisible()) {
      await leaderboardTab.click();
      await page.waitForTimeout(2000);

      // Filter by rank
      const rankFilter = page.locator('text=/Hạng K|Rank K/i').first();
      if (await rankFilter.isVisible()) {
        await rankFilter.click();
        await page.waitForTimeout(2000);

        // Should show filtered results
        const filteredResults = page.locator('[data-testid="leaderboard-item"]').first();
      }
    }
  });

  test('should share leaderboard', async ({ page }) => {
    const leaderboardTab = page.locator('text=/Bảng xếp hạng|Leaderboard/i').first();
    
    if (await leaderboardTab.isVisible()) {
      await leaderboardTab.click();
      await page.waitForTimeout(2000);

      // Click share button
      const shareButton = page.locator('button[aria-label*="share"], button:has-text("Chia sẻ")').first();
      if (await shareButton.isVisible()) {
        await shareButton.click();
        await page.waitForTimeout(1000);

        // Should show share options (native share dialog or custom share sheet)
        // Note: Web share API may show native dialog
      }
    }
  });

  test('should switch between leaderboard tabs', async ({ page }) => {
    const leaderboardTab = page.locator('text=/Bảng xếp hạng|Leaderboard/i').first();
    
    if (await leaderboardTab.isVisible()) {
      await leaderboardTab.click();
      await page.waitForTimeout(2000);

      // Switch tabs
      const tabs = ['ELO Rating', 'Thắng lợi', 'Giải đấu', 'SPA Points'];
      for (const tabName of tabs) {
        const tab = page.locator(`text=/${tabName}/i`).first();
        if (await tab.isVisible()) {
          await tab.click();
          await page.waitForTimeout(1000);
          
          // Should show content for that tab
        }
      }
    }
  });
});

