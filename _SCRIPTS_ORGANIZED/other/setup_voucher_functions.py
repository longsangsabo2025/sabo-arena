#!/usr/bin/env python3
"""
Setup only helper functions for voucher system
"""

import psycopg2
import sys

DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"

def setup_functions():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        
        print("🔧 Setting up voucher helper functions...")
        
        # Drop and recreate functions
        functions_sql = """
        -- Drop existing functions
        DROP FUNCTION IF EXISTS public.generate_voucher_code();
        DROP FUNCTION IF EXISTS public.check_campaign_eligibility(UUID, UUID);
        DROP FUNCTION IF EXISTS public.issue_voucher(UUID, UUID, UUID, TEXT, JSONB);
        DROP FUNCTION IF EXISTS public.use_voucher(TEXT, UUID, DECIMAL, TEXT);
        
        -- Voucher code generator
        CREATE FUNCTION public.generate_voucher_code()
        RETURNS TEXT AS $$
        DECLARE
            code TEXT;
        BEGIN
            code := UPPER(substring(md5(random()::text || clock_timestamp()::text), 1, 12));
            WHILE EXISTS (SELECT 1 FROM public.user_vouchers WHERE voucher_code = code) LOOP
                code := UPPER(substring(md5(random()::text || clock_timestamp()::text), 1, 12));
            END LOOP;
            RETURN code;
        END;
        $$ LANGUAGE plpgsql;

        -- Campaign eligibility checker
        CREATE FUNCTION public.check_campaign_eligibility(
            p_campaign_id UUID,
            p_user_id UUID
        )
        RETURNS BOOLEAN AS $$
        DECLARE
            campaign_record RECORD;
            user_voucher_count INTEGER;
        BEGIN
            SELECT * INTO campaign_record
            FROM public.voucher_campaigns 
            WHERE id = p_campaign_id 
            AND status = 'active'
            AND start_date <= NOW()
            AND end_date > NOW();
            
            IF NOT FOUND THEN
                RETURN FALSE;
            END IF;
            
            SELECT COUNT(*) INTO user_voucher_count
            FROM public.user_vouchers
            WHERE campaign_id = p_campaign_id
            AND user_id = p_user_id;
            
            IF user_voucher_count >= campaign_record.max_per_user THEN
                RETURN FALSE;
            END IF;
            
            IF campaign_record.total_issued >= campaign_record.max_redemptions THEN
                RETURN FALSE;
            END IF;
            
            RETURN TRUE;
        END;
        $$ LANGUAGE plpgsql;

        -- Issue voucher function
        CREATE FUNCTION public.issue_voucher(
            p_campaign_id UUID,
            p_user_id UUID,
            p_club_id UUID,
            p_issue_reason TEXT DEFAULT 'manual',
            p_issue_details JSONB DEFAULT '{}'
        )
        RETURNS UUID AS $$
        DECLARE
            voucher_id UUID;
            campaign_record RECORD;
            expires_date TIMESTAMPTZ;
        BEGIN
            IF NOT public.check_campaign_eligibility(p_campaign_id, p_user_id) THEN
                RAISE EXCEPTION 'User not eligible for this campaign';
            END IF;
            
            SELECT * INTO campaign_record
            FROM public.voucher_campaigns 
            WHERE id = p_campaign_id;
            
            expires_date := LEAST(
                NOW() + INTERVAL '30 days',
                campaign_record.end_date
            );
            
            INSERT INTO public.user_vouchers (
                campaign_id, user_id, club_id, voucher_code, status,
                issue_reason, issue_details, rewards, usage_rules, expires_at
            ) VALUES (
                p_campaign_id, p_user_id, p_club_id, public.generate_voucher_code(), 'active',
                p_issue_reason, p_issue_details, campaign_record.rewards, 
                campaign_record.rules, expires_date
            )
            RETURNING id INTO voucher_id;
            
            UPDATE public.voucher_campaigns
            SET total_issued = total_issued + 1
            WHERE id = p_campaign_id;
            
            RETURN voucher_id;
        END;
        $$ LANGUAGE plpgsql;

        -- Use voucher function
        CREATE FUNCTION public.use_voucher(
            p_voucher_code TEXT,
            p_user_id UUID,
            p_original_amount DECIMAL DEFAULT 0,
            p_session_id TEXT DEFAULT NULL
        )
        RETURNS JSONB AS $$
        DECLARE
            voucher_record RECORD;
            discount_amount DECIMAL;
            final_amount DECIMAL;
            bonus_time INTEGER;
            result JSONB;
        BEGIN
            SELECT uv.*, vc.rewards
            INTO voucher_record
            FROM public.user_vouchers uv
            JOIN public.voucher_campaigns vc ON uv.campaign_id = vc.id
            WHERE uv.voucher_code = p_voucher_code
            AND uv.user_id = p_user_id
            AND uv.status = 'active'
            AND (uv.expires_at IS NULL OR uv.expires_at > NOW());
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Voucher not found or invalid';
            END IF;
            
            discount_amount := COALESCE(
                (voucher_record.rewards->>'discount_amount')::DECIMAL,
                p_original_amount * COALESCE((voucher_record.rewards->>'discount_percentage')::DECIMAL, 0) / 100
            );
            
            final_amount := GREATEST(0, p_original_amount - discount_amount);
            bonus_time := COALESCE((voucher_record.rewards->>'bonus_time_minutes')::INTEGER, 0);
            
            UPDATE public.user_vouchers
            SET status = 'used', used_at = NOW(),
                used_details = jsonb_build_object(
                    'session_id', p_session_id,
                    'original_amount', p_original_amount,
                    'discount_amount', discount_amount,
                    'final_amount', final_amount
                )
            WHERE id = voucher_record.id;
            
            INSERT INTO public.voucher_usage_history (
                voucher_id, user_id, club_id, session_id,
                original_amount, discount_amount, final_amount, bonus_time_minutes
            ) VALUES (
                voucher_record.id, p_user_id, voucher_record.club_id, p_session_id,
                p_original_amount, discount_amount, final_amount, bonus_time
            );
            
            UPDATE public.voucher_campaigns
            SET total_used = total_used + 1
            WHERE id = voucher_record.campaign_id;
            
            result := jsonb_build_object(
                'success', TRUE,
                'original_amount', p_original_amount,
                'discount_amount', discount_amount,
                'final_amount', final_amount,
                'bonus_time_minutes', bonus_time
            );
            
            RETURN result;
        END;
        $$ LANGUAGE plpgsql;
        """
        
        cursor.execute(functions_sql)
        conn.commit()
        
        print("✅ Functions created successfully!")
        
        # Verify functions
        cursor.execute("""
            SELECT proname FROM pg_proc p 
            JOIN pg_namespace n ON p.pronamespace = n.oid 
            WHERE n.nspname = 'public' 
            AND proname IN ('generate_voucher_code', 'check_campaign_eligibility', 'issue_voucher', 'use_voucher');
        """)
        functions = cursor.fetchall()
        
        print(f"✅ Verified {len(functions)} functions:")
        for func in functions:
            print(f"   • {func[0]}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = setup_functions()
    sys.exit(0 if success else 1)