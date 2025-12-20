-- Fix notification to show correct requested rank instead of current rank
-- Date: 2025-12-20

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
    v_result JSON;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get the rank request with requested_rank
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

    -- If approved, add user to club members and create notification
    IF p_approved THEN
        -- Auto-add user to club members if not already a member
        INSERT INTO club_members (club_id, user_id, role, joined_at)
        VALUES (v_request.club_id, v_request.user_id, 'member', NOW())
        ON CONFLICT (club_id, user_id) DO NOTHING;

        -- Determine the rank to show in notification (use requested_rank if available)
        DECLARE
            v_rank_for_notification TEXT;
        BEGIN
            -- Use requested_rank if available, otherwise use current rank
            IF v_request.requested_rank IS NOT NULL AND v_request.requested_rank != '' THEN
                v_rank_for_notification := v_request.requested_rank;
            ELSE
                -- Try to parse from notes as fallback
                v_rank_for_notification := substring(v_request.notes FROM 'Rank mong muốn: ([A-K])');
                IF v_rank_for_notification IS NULL OR v_rank_for_notification = '' THEN
                    v_rank_for_notification := v_request.user_current_rank;
                END IF;
            END IF;

            -- Create success notification with CORRECT rank
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
                format('Chúc mừng! Hạng %s của bạn đã được CLB xác nhận', v_rank_for_notification),
                jsonb_build_object(
                    'request_id', p_request_id,
                    'requested_rank', v_rank_for_notification,
                    'approved_by', v_user_id,
                    'club_id', v_request.club_id
                ),
                NOW()
            );
        END;
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
            'Yêu cầu xác minh hạng bị từ chối',
            format('Yêu cầu xác minh hạng của bạn đã bị từ chối. Lý do: %s', COALESCE(p_comments, 'Không có lý do')),
            jsonb_build_object(
                'request_id', p_request_id,
                'rejection_reason', p_comments,
                'club_id', v_request.club_id
            ),
            NOW()
        );
    END IF;

    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', CASE 
            WHEN p_approved THEN 'Request approved successfully'
            ELSE 'Request rejected'
        END,
        'request_id', p_request_id,
        'status', CASE 
            WHEN p_approved THEN 'approved'
            ELSE 'rejected'
        END
    );

    RETURN v_result;
END;
$$;

-- Verify the function was updated
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name = 'admin_approve_rank_change_request'
    ) THEN
        RAISE NOTICE '✅ Function admin_approve_rank_change_request updated successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to update function';
    END IF;
END $$;
