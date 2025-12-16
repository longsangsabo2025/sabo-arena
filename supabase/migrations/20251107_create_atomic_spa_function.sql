-- ============================================================================
-- CREATE ATOMIC SPA INCREMENT FUNCTION
-- Giải quyết race condition khi nhiều transactions cùng lúc
-- ============================================================================

CREATE OR REPLACE FUNCTION atomic_increment_spa(
    p_user_id UUID,
    p_amount INTEGER,
    p_transaction_type VARCHAR,
    p_description TEXT,
    p_reference_type VARCHAR DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL
)
RETURNS TABLE (
    old_balance INTEGER,
    new_balance INTEGER,
    transaction_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_old_balance INTEGER;
    v_new_balance INTEGER;
    v_transaction_id UUID;
BEGIN
    -- ✅ ATOMIC: Lock row và update trong 1 operation
    UPDATE users
    SET spa_points = spa_points + p_amount
    WHERE id = p_user_id
    RETURNING spa_points - p_amount, spa_points
    INTO v_old_balance, v_new_balance;
    
    -- Kiểm tra user có tồn tại không
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;
    
    -- Tạo transaction record
    INSERT INTO spa_transactions (
        user_id,
        transaction_type,
        amount,
        balance_before,
        balance_after,
        reference_type,
        reference_id,
        description,
        created_at
    ) VALUES (
        p_user_id,
        p_transaction_type,
        p_amount,
        v_old_balance,
        v_new_balance,
        p_reference_type,
        p_reference_id,
        p_description,
        NOW()
    )
    RETURNING id INTO v_transaction_id;
    
    -- Return results
    RETURN QUERY SELECT v_old_balance, v_new_balance, v_transaction_id;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION atomic_increment_spa TO authenticated;
GRANT EXECUTE ON FUNCTION atomic_increment_spa TO service_role;

COMMENT ON FUNCTION atomic_increment_spa IS 
'Atomically increment user SPA points and create transaction record. 
Prevents race conditions when multiple rewards are distributed simultaneously.';
