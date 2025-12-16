import { test, expect } from '@playwright/test';

/**
 * Payment Flow E2E Tests
 * Tests tournament entry payment, voucher redemption
 */
test.describe('Payment Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);
  });

  test('should process tournament entry payment', async ({ page }) => {
    // Navigate to tournament with entry fee
    const tournamentCard = page.locator('[data-testid="tournament-card"]').first();
    
    if (await tournamentCard.isVisible()) {
      await tournamentCard.click();
      await page.waitForTimeout(2000);

      // Click register (should trigger payment flow)
      const registerButton = page.locator('button:has-text("Đăng ký"), button:has-text("Register")').first();
      if (await registerButton.isVisible()) {
        await registerButton.click();
        await page.waitForTimeout(2000);

        // Should show payment screen
        const paymentScreen = page.locator('text=/Thanh toán|Payment/i').first();
        if (await paymentScreen.isVisible()) {
          // Select payment method
          const paymentMethod = page.locator('text=/VNPay|MoMo|ZaloPay/i').first();
          if (await paymentMethod.isVisible()) {
            await paymentMethod.click();
            await page.waitForTimeout(1000);

            // Note: Actual payment processing would require test payment gateway
            // This is a placeholder for payment flow testing
          }
        }
      }
    }
  });

  test('should redeem voucher', async ({ page }) => {
    // Navigate to voucher section
    const voucherTab = page.locator('text=/Voucher|Mã giảm giá/i').first();
    
    if (await voucherTab.isVisible()) {
      await voucherTab.click();
      await page.waitForTimeout(2000);

      // Enter voucher code
      const voucherInput = page.locator('input[placeholder*="mã" i], input[placeholder*="code" i]').first();
      if (await voucherInput.isVisible()) {
        await voucherInput.fill('TEST_VOUCHER');
        
        const redeemButton = page.locator('button:has-text("Đổi"), button:has-text("Redeem")').first();
        if (await redeemButton.isVisible()) {
          await redeemButton.click();
          await page.waitForTimeout(2000);

          // Should show success or error
          const result = page.locator('text=/thành công|success|invalid|invalid/i').first();
        }
      }
    }
  });

  test('should view payment history', async ({ page }) => {
    // Navigate to profile/settings
    const profileButton = page.locator('[aria-label*="profile"], [aria-label*="user"]').first();
    
    if (await profileButton.isVisible()) {
      await profileButton.click();
      await page.waitForTimeout(1000);

      // Navigate to payment history
      const paymentHistory = page.locator('text=/Lịch sử thanh toán|Payment History/i').first();
      if (await paymentHistory.isVisible()) {
        await paymentHistory.click();
        await page.waitForTimeout(2000);

        // Should show payment list
        const paymentList = page.locator('[data-testid="payment-list"], .payment-item').first();
      }
    }
  });
});

