-- Migration: Add Payment Refund System
-- Date: 2025-10-20
-- Description: Add tables and functions for handling payment refunds

-- 1. Create refund_requests table
CREATE TABLE IF NOT EXISTS public.refund_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES public.payment_transactions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    reason TEXT NOT NULL,
    additional_notes TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'processing')),
    reviewed_by UUID REFERENCES public.users(id),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    cancelled_at TIMESTAMPTZ,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add indexes for performance
CREATE INDEX idx_refund_requests_transaction ON public.refund_requests(transaction_id);
CREATE INDEX idx_refund_requests_user ON public.refund_requests(user_id);
CREATE INDEX idx_refund_requests_status ON public.refund_requests(status);
CREATE INDEX idx_refund_requests_requested_at ON public.refund_requests(requested_at);

-- 3. Add refund tracking columns to payment_transactions
ALTER TABLE public.payment_transactions
ADD COLUMN IF NOT EXISTS refund_status VARCHAR(20) DEFAULT 'none' CHECK (refund_status IN ('none', 'requested', 'processing', 'refunded', 'rejected')),
ADD COLUMN IF NOT EXISTS refunded_amount DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMPTZ;

-- 4. Create stored procedure to process refund
CREATE OR REPLACE FUNCTION public.process_refund(
    p_refund_request_id UUID,
    p_transaction_id UUID,
    p_user_id UUID,
    p_amount DECIMAL,
    p_admin_id UUID,
    p_admin_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Start transaction
    BEGIN
        -- 1. Update refund request status
        UPDATE public.refund_requests
        SET 
            status = 'approved',
            reviewed_by = p_admin_id,
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_refund_request_id;

        -- 2. Update payment transaction
        UPDATE public.payment_transactions
        SET 
            refund_status = 'refunded',
            refunded_amount = p_amount,
            refunded_at = NOW(),
            status = 'refunded',
            updated_at = NOW()
        WHERE id = p_transaction_id;

        -- 3. Return refunded amount to user (if applicable)
        -- This depends on your payment method
        -- For tournament entry fees, you might want to add back to user's balance

        -- 4. Log the refund
        INSERT INTO public.admin_activity_logs (
            admin_id,
            action_type,
            target_type,
            target_id,
            details,
            created_at
        ) VALUES (
            p_admin_id,
            'refund_approved',
            'refund_request',
            p_refund_request_id,
            jsonb_build_object(
                'transaction_id', p_transaction_id,
                'amount', p_amount,
                'admin_notes', p_admin_notes
            ),
            NOW()
        );

        v_result := jsonb_build_object(
            'success', true,
            'message', 'Refund processed successfully',
            'refund_request_id', p_refund_request_id,
            'amount', p_amount
        );

        RETURN v_result;

    EXCEPTION WHEN OTHERS THEN
        -- Rollback will happen automatically
        v_result := jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
        RETURN v_result;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create function to check refund eligibility
CREATE OR REPLACE FUNCTION public.check_refund_eligibility(
    p_transaction_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_transaction RECORD;
    v_result JSONB;
    v_days_since INTEGER;
BEGIN
    -- Get transaction details
    SELECT * INTO v_transaction
    FROM public.payment_transactions
    WHERE id = p_transaction_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'is_eligible', false,
            'reason', 'Transaction not found'
        );
    END IF;

    -- Check if already refunded
    IF v_transaction.status = 'refunded' THEN
        RETURN jsonb_build_object(
            'is_eligible', false,
            'reason', 'Transaction already refunded'
        );
    END IF;

    -- Check if completed
    IF v_transaction.status != 'completed' THEN
        RETURN jsonb_build_object(
            'is_eligible', false,
            'reason', 'Only completed transactions can be refunded'
        );
    END IF;

    -- Check 30-day window
    v_days_since := EXTRACT(DAY FROM (NOW() - v_transaction.created_at));
    
    IF v_days_since > 30 THEN
        RETURN jsonb_build_object(
            'is_eligible', false,
            'reason', 'Refund window expired (30 days maximum)'
        );
    END IF;

    -- All checks passed
    RETURN jsonb_build_object(
        'is_eligible', true,
        'days_remaining', 30 - v_days_since,
        'amount', v_transaction.amount
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Enable RLS on refund_requests
ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for refund_requests
-- Users can view their own refund requests
CREATE POLICY "Users can view own refund requests"
    ON public.refund_requests FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create refund requests for their own transactions
CREATE POLICY "Users can create own refund requests"
    ON public.refund_requests FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can cancel their own pending refund requests
CREATE POLICY "Users can cancel own pending refunds"
    ON public.refund_requests FOR UPDATE
    USING (auth.uid() = user_id AND status = 'pending')
    WITH CHECK (status = 'cancelled');

-- Admins can view all refund requests
CREATE POLICY "Admins can view all refund requests"
    ON public.refund_requests FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'moderator')
        )
    );

-- Admins can update refund requests
CREATE POLICY "Admins can update refund requests"
    ON public.refund_requests FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'moderator')
        )
    );

-- 8. Create trigger to update updated_at
CREATE OR REPLACE FUNCTION public.update_refund_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_refund_requests_updated_at
    BEFORE UPDATE ON public.refund_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.update_refund_requests_updated_at();

-- 9. Add comments for documentation
COMMENT ON TABLE public.refund_requests IS 'Stores payment refund requests from users';
COMMENT ON COLUMN public.refund_requests.status IS 'Refund status: pending, approved, rejected, cancelled, processing';
COMMENT ON FUNCTION public.process_refund IS 'Process approved refund and update related records';
COMMENT ON FUNCTION public.check_refund_eligibility IS 'Check if a transaction is eligible for refund';
