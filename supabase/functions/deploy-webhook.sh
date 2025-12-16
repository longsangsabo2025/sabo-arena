#!/bin/bash

# Deploy MoMo Webhook to Supabase Edge Functions

echo "🚀 Deploying MoMo Webhook..."

# Set secrets
echo "📝 Setting secrets..."
supabase secrets set MOMO_SECRET_KEY="IQrXZ15zOzPCzrUqCbqbuyr9vl0v0K9R"

# Deploy function
echo "📦 Deploying function..."
supabase functions deploy momo-webhook --no-verify-jwt

echo "✅ Deployment complete!"
echo ""
echo "📋 Webhook URL:"
echo "https://your-project-ref.supabase.co/functions/v1/momo-webhook"
echo ""
echo "⚙️  Next steps:"
echo "1. Copy the webhook URL above"
echo "2. Update PaymentConfig.momoNotifyUrl with this URL"
echo "3. Test the webhook with a payment"
