-- =====================================================
-- Add Missing Platform Settings and Voucher Templates
-- Fixes: Missing ELO settings and voucher template 'top_4'
-- =====================================================

-- =====================================================
-- 1. ADD PLATFORM SETTINGS FOR ELO (if not exists)
-- =====================================================

-- Check if platform_settings table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'platform_settings') THEN
        -- Create platform_settings table if it doesn't exist
        CREATE TABLE IF NOT EXISTS public.platform_settings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            setting_key TEXT UNIQUE NOT NULL,
            setting_value JSONB NOT NULL,
            description TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        RAISE NOTICE 'Created platform_settings table';
    END IF;
END $$;

-- Insert default ELO settings if not exists
INSERT INTO public.platform_settings (setting_key, setting_value, description)
VALUES (
    'elo_system',
    '{
        "enabled": true,
        "k_factor": 32,
        "initial_elo": 1500,
        "min_elo": 0,
        "max_elo": 3000,
        "tournament_multiplier": 1.5
    }'::jsonb,
    'ELO rating system configuration'
)
ON CONFLICT (setting_key) DO NOTHING;

-- =====================================================
-- 2. ADD VOUCHER TEMPLATE 'top_4' (if not exists)
-- =====================================================

-- Check if voucher_templates table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'voucher_templates') THEN
        -- Create voucher_templates table if it doesn't exist
        CREATE TABLE IF NOT EXISTS public.voucher_templates (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            template_id TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            campaign_type TEXT NOT NULL,
            target_type TEXT NOT NULL,
            template_data JSONB NOT NULL,
            is_active BOOLEAN DEFAULT true,
            usage_count INT DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        RAISE NOTICE 'Created voucher_templates table';
    END IF;
END $$;

-- Insert 'top_4' voucher template if not exists
INSERT INTO public.voucher_templates (template_id, title, description, category, campaign_type, target_type, template_data, is_active)
VALUES (
    'top_4',
    'Top 4 Tournament Winners',
    'Voucher rewards for top 4 positions in tournaments',
    'achievement',
    'tournament_prize',
    'top_performers',
    '{
        "positions": [
            {
                "position": 1,
                "voucher_type": "discount_percentage",
                "discount_value": 50,
                "max_discount_amount": 500000,
                "description": "Giảm 50% cho nhà vô địch",
                "valid_days": 30
            },
            {
                "position": 2,
                "voucher_type": "discount_percentage",
                "discount_value": 30,
                "max_discount_amount": 300000,
                "description": "Giảm 30% cho á quân",
                "valid_days": 30
            },
            {
                "position": 3,
                "voucher_type": "discount_percentage",
                "discount_value": 20,
                "max_discount_amount": 200000,
                "description": "Giảm 20% cho hạng 3",
                "valid_days": 30
            },
            {
                "position": 4,
                "voucher_type": "discount_percentage",
                "discount_value": 10,
                "max_discount_amount": 100000,
                "description": "Giảm 10% cho hạng 4",
                "valid_days": 30
            }
        ]
    }'::jsonb,
    true
)
ON CONFLICT (template_id) DO UPDATE SET
    template_data = EXCLUDED.template_data,
    updated_at = NOW();

-- =====================================================
-- 3. VERIFICATION
-- =====================================================

-- Verify ELO settings
DO $$
DECLARE
    elo_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.platform_settings 
        WHERE setting_key = 'elo_system'
    ) INTO elo_exists;
    
    IF elo_exists THEN
        RAISE NOTICE '✅ ELO platform settings verified';
    ELSE
        RAISE WARNING '⚠️ ELO platform settings NOT found';
    END IF;
END $$;

-- Verify voucher template
DO $$
DECLARE
    voucher_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.voucher_templates 
        WHERE template_id = 'top_4'
    ) INTO voucher_exists;
    
    IF voucher_exists THEN
        RAISE NOTICE '✅ Voucher template top_4 verified';
    ELSE
        RAISE WARNING '⚠️ Voucher template top_4 NOT found';
    END IF;
END $$;

-- =====================================================
-- DONE
-- =====================================================
