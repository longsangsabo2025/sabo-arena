-- =====================================================
-- SIMPLE RANK APPROVAL FUNCTION FOR CLUB OWNERS ONLY
-- =====================================================

DROP FUNCTION IF EXISTS admin_approve_rank_change_request(UUID, BOOLEAN, TEXT);

-- Simple function for club owners to approve/reject rank requests
CREATE OR REPLACE FUNCTION admin_approve_rank_change_request(
    p_request_id UUID,
    p_approved BOOLEAN,
    p_comments TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_request RECORD;
    v_user_current_rank TEXT;
    v_result JSON;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get the rank request with user's current rank
    SELECT 
        rr.*,
        u.rank as user_current_rank
    INTO v_request
    FROM rank_requests rr
    JOIN users u ON u.id = rr.user_id
    WHERE rr.id = p_request_id;

    IF v_request IS NULL THEN
        RAISE EXCEPTION 'Request not found';
    END IF;

    -- Check if already processed
    IF v_request.status != 'pending' THEN
        RAISE EXCEPTION 'Request has already been processed';
    END IF;

    -- Check if user is the club owner
    IF NOT EXISTS(
        SELECT 1 FROM clubs
        WHERE id = v_request.club_id
        AND owner_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Access denied: Only club owner can approve requests';
    END IF;

    -- Update rank_requests table
    UPDATE rank_requests
    SET 
        status = CASE 
            WHEN p_approved THEN 'approved'::request_status
            ELSE 'rejected'::request_status
        END,
        reviewed_by = v_user_id,
        reviewed_at = NOW(),
        rejection_reason = CASE 
            WHEN NOT p_approved THEN p_comments 
            ELSE NULL 
        END
    WHERE id = p_request_id;

    -- If approved, just verify user already has rank
    -- (rank_requests is just for club verification, user already has rank from system)
    IF p_approved THEN

    -- If approved, just verify user already has rank
    -- (rank_requests is just for club verification, user already has rank from system)
    IF p_approved THEN
        -- Auto-add user to club members if not already a member
        INSERT INTO club_members (club_id, user_id, role, joined_at)
        VALUES (v_request.club_id, v_request.user_id, 'member', NOW())
        ON CONFLICT (club_id, user_id) DO NOTHING;

        -- Create success notification
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data,
            created_at
        ) VALUES (
            v_request.user_id,
            'rank_change_approved',
            'Yêu cầu xác minh hạng đã được duyệt! 🎉',
            format('Chúc mừng! Hạng %s của bạn đã được CLB xác nhận', v_request.user_current_rank),
            jsonb_build_object(
                'request_id', p_request_id,
                'current_rank', v_request.user_current_rank,
                'approved_by', v_user_id,
                'club_id', v_request.club_id
            ),
            NOW()
        );
    ELSE
        -- Create rejection notification
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data,
            created_at
        ) VALUES (
            v_request.user_id,
            'rank_change_rejected',
            'Yêu cầu xác minh hạng đã bị từ chối',
            format('CLB đã từ chối xác minh hạng. Lý do: %s', COALESCE(p_comments, 'Không có lý do cụ thể')),
            jsonb_build_object(
                'request_id', p_request_id,
                'current_rank', v_request.user_current_rank,
                'rejected_by', v_user_id,
                'reason', p_comments,
                'club_id', v_request.club_id
            ),
            NOW()
        );
    END IF;

    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', CASE 
            WHEN p_approved THEN 'Đã duyệt xác minh hạng thành công'
            ELSE 'Đã từ chối yêu cầu'
        END,
        'status', CASE 
            WHEN p_approved THEN 'approved'
            ELSE 'rejected'
        END,
        'current_rank', v_request.user_current_rank,
        'user_id', v_request.user_id
    );

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION admin_approve_rank_change_request TO authenticated;

COMMENT ON FUNCTION admin_approve_rank_change_request IS 
'Allows club owners to approve or reject rank verification requests. This only verifies that the user belongs to the club - rank is managed separately by the system.';
