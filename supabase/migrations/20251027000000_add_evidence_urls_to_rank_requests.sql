-- Migration: Add evidence_urls column to rank_requests table
-- Date: 2025-10-27
-- Purpose: Fix issue where users cannot submit rank requests with evidence

-- Add evidence_urls column to store image URLs
ALTER TABLE public.rank_requests 
ADD COLUMN IF NOT EXISTS evidence_urls TEXT[];

-- Add comment
COMMENT ON COLUMN public.rank_requests.evidence_urls IS 'Array of image URLs uploaded as evidence for rank request';

-- Verify the column was added
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'rank_requests' 
        AND column_name = 'evidence_urls'
    ) THEN
        RAISE NOTICE '✅ Column evidence_urls added successfully to rank_requests table';
    ELSE
        RAISE EXCEPTION '❌ Failed to add evidence_urls column';
    END IF;
END $$;
