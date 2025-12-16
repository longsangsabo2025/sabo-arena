import { test, expect } from '@playwright/test';

/**
 * Performance E2E Tests
 * Tests app performance, load times, responsiveness
 */
test.describe('Performance', () => {
  test('should load app within acceptable time', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto('/');
    
    // Wait for main content to load
    await page.waitForLoadState('networkidle');
    
    const loadTime = Date.now() - startTime;
    
    // App should load within 5 seconds
    expect(loadTime).toBeLessThan(5000);
  });

  test('should have acceptable Time to Interactive', async ({ page }) => {
    await page.goto('/');
    
    // Measure TTI (Time to Interactive)
    const tti = await page.evaluate(() => {
      return performance.timing.domInteractive - performance.timing.navigationStart;
    });
    
    // TTI should be less than 3 seconds
    expect(tti).toBeLessThan(3000);
  });

  test('should handle rapid navigation', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(1000);

    // Rapidly navigate between screens
    const tabs = ['Tournament', 'Club', 'Leaderboard', 'Profile'];
    
    for (const tab of tabs) {
      const tabElement = page.locator(`text=/${tab}/i`).first();
      if (await tabElement.isVisible()) {
        await tabElement.click();
        await page.waitForTimeout(500);
      }
    }

    // Should not crash or show errors
    const errorMessage = page.locator('text=/error|crash|failed/i');
    await expect(errorMessage).toHaveCount(0);
  });

  test('should load tournament list efficiently', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);

    const startTime = Date.now();
    
    const tournamentTab = page.locator('text=/Giải đấu|Tournament/i').first();
    if (await tournamentTab.isVisible()) {
      await tournamentTab.click();
      await page.waitForLoadState('networkidle');
    }
    
    const loadTime = Date.now() - startTime;
    
    // Tournament list should load within 2 seconds
    expect(loadTime).toBeLessThan(2000);
  });

  test('should handle image loading gracefully', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);

    // Check for broken images
    const brokenImages = await page.evaluate(() => {
      const images = Array.from(document.querySelectorAll('img'));
      return images.filter(img => !img.complete || img.naturalHeight === 0).length;
    });

    // Should have no broken images
    expect(brokenImages).toBe(0);
  });
});

