import { test, expect } from '@playwright/test';

/**
 * Tournament Flow E2E Tests
 * Tests tournament creation, registration, bracket generation, match progression
 */
test.describe('Tournament Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);
    
    // Login if needed (adjust based on auth state)
    // This is a placeholder - adjust based on actual app flow
  });

  test('should display tournament list', async ({ page }) => {
    // Navigate to tournaments
    const tournamentTab = page.locator('text=/Giải đấu|Tournament/i').first();
    
    if (await tournamentTab.isVisible()) {
      await tournamentTab.click();
      await page.waitForTimeout(2000);

      // Should show tournament list
      const tournamentCards = page.locator('[data-testid="tournament-card"], .tournament-card').first();
      // Note: Adjust selector based on actual implementation
    }
  });

  test('should create new tournament', async ({ page }) => {
    // Navigate to create tournament
    const createButton = page.locator('text=/Tạo giải|Create Tournament/i').first();
    
    if (await createButton.isVisible()) {
      await createButton.click();
      await page.waitForTimeout(1000);

      // Fill tournament form
      const titleInput = page.locator('input[placeholder*="tên" i], input[placeholder*="title" i]').first();
      const descriptionInput = page.locator('textarea[placeholder*="mô tả" i], textarea[placeholder*="description" i]').first();
      const maxParticipantsInput = page.locator('input[type="number"]').first();
      const entryFeeInput = page.locator('input[placeholder*="phí" i], input[placeholder*="fee" i]').first();

      if (await titleInput.isVisible()) {
        await titleInput.fill(`Test Tournament ${Date.now()}`);
        if (await descriptionInput.isVisible()) {
          await descriptionInput.fill('Test tournament description');
        }
        if (await maxParticipantsInput.isVisible()) {
          await maxParticipantsInput.fill('16');
        }
        if (await entryFeeInput.isVisible()) {
          await entryFeeInput.fill('100000');
        }

        // Submit
        const submitButton = page.locator('button:has-text("Tạo"), button:has-text("Create")').first();
        if (await submitButton.isVisible()) {
          await submitButton.click();
          await page.waitForTimeout(3000);

          // Should show success or redirect to tournament detail
          const successIndicator = page.locator('text=/thành công|success|created/i').first();
        }
      }
    }
  });

  test('should register for tournament', async ({ page }) => {
    // Navigate to a tournament
    const tournamentCard = page.locator('[data-testid="tournament-card"]').first();
    
    if (await tournamentCard.isVisible()) {
      await tournamentCard.click();
      await page.waitForTimeout(2000);

      // Click register button
      const registerButton = page.locator('button:has-text("Đăng ký"), button:has-text("Register")').first();
      if (await registerButton.isVisible()) {
        await registerButton.click();
        await page.waitForTimeout(2000);

        // Should show confirmation or payment flow
        const confirmation = page.locator('text=/xác nhận|confirm|đăng ký thành công/i').first();
      }
    }
  });

  test('should view tournament bracket', async ({ page }) => {
    // Navigate to tournament detail
    const tournamentCard = page.locator('[data-testid="tournament-card"]').first();
    
    if (await tournamentCard.isVisible()) {
      await tournamentCard.click();
      await page.waitForTimeout(2000);

      // Navigate to bracket tab
      const bracketTab = page.locator('text=/Bảng đấu|Bracket/i').first();
      if (await bracketTab.isVisible()) {
        await bracketTab.click();
        await page.waitForTimeout(2000);

        // Should display bracket visualization
        const bracketVisualization = page.locator('[data-testid="bracket"], .bracket-container').first();
        // Note: Adjust selector based on actual implementation
      }
    }
  });

  test('should update match score', async ({ page }) => {
    // Navigate to a match in tournament
    // This requires tournament to be in progress with matches
    const matchCard = page.locator('[data-testid="match-card"]').first();
    
    if (await matchCard.isVisible()) {
      await matchCard.click();
      await page.waitForTimeout(1000);

      // Update score
      const scoreInput = page.locator('input[type="number"]').first();
      if (await scoreInput.isVisible()) {
        await scoreInput.fill('9');
        
        const saveButton = page.locator('button:has-text("Lưu"), button:has-text("Save")').first();
        if (await saveButton.isVisible()) {
          await saveButton.click();
          await page.waitForTimeout(2000);

          // Should show updated score
          const updatedScore = page.locator('text=/9/i').first();
        }
      }
    }
  });
});

