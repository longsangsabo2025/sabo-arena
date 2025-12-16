-- ============================================================================
-- Club Reviews System Migration
-- ============================================================================
-- Created: 2025-10-20
-- Purpose: Enable club rating and review system
-- ============================================================================

-- Create club_reviews table
CREATE TABLE IF NOT EXISTS club_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Ratings
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
    facility_rating DECIMAL(2,1) CHECK (facility_rating >= 1 AND facility_rating <= 5),
    service_rating DECIMAL(2,1) CHECK (service_rating >= 1 AND service_rating <= 5),
    atmosphere_rating DECIMAL(2,1) CHECK (atmosphere_rating >= 1 AND atmosphere_rating <= 5),
    price_rating DECIMAL(2,1) CHECK (price_rating >= 1 AND price_rating <= 5),
    
    -- Review content
    comment TEXT,
    image_urls TEXT[], -- Array of image URLs
    
    -- Metadata
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    UNIQUE(club_id, user_id) -- One review per user per club
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_club_reviews_club_id ON club_reviews(club_id);
CREATE INDEX IF NOT EXISTS idx_club_reviews_user_id ON club_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_club_reviews_rating ON club_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_club_reviews_created_at ON club_reviews(created_at DESC);

-- Add total_reviews column to clubs table if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clubs' AND column_name = 'total_reviews'
    ) THEN
        ALTER TABLE clubs ADD COLUMN total_reviews INTEGER DEFAULT 0;
    END IF;
END $$;

-- ============================================================================
-- RLS (Row Level Security) Policies
-- ============================================================================

-- Enable RLS
ALTER TABLE club_reviews ENABLE ROW LEVEL SECURITY;

-- Anyone can read reviews
CREATE POLICY "Anyone can read club reviews"
    ON club_reviews FOR SELECT
    USING (true);

-- Users can insert their own reviews
CREATE POLICY "Users can insert their own reviews"
    ON club_reviews FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own reviews
CREATE POLICY "Users can update their own reviews"
    ON club_reviews FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own reviews
CREATE POLICY "Users can delete their own reviews"
    ON club_reviews FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Function to get club review statistics
CREATE OR REPLACE FUNCTION get_club_review_stats(club_id_param UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'average_rating', COALESCE(AVG(rating), 0),
        'total_reviews', COUNT(*),
        'rating_distribution', json_build_object(
            '5', COUNT(*) FILTER (WHERE rating >= 4.5),
            '4', COUNT(*) FILTER (WHERE rating >= 3.5 AND rating < 4.5),
            '3', COUNT(*) FILTER (WHERE rating >= 2.5 AND rating < 3.5),
            '2', COUNT(*) FILTER (WHERE rating >= 1.5 AND rating < 2.5),
            '1', COUNT(*) FILTER (WHERE rating < 1.5)
        ),
        'average_facility_rating', AVG(facility_rating),
        'average_service_rating', AVG(service_rating),
        'average_atmosphere_rating', AVG(atmosphere_rating),
        'average_price_rating', AVG(price_rating)
    ) INTO result
    FROM club_reviews
    WHERE club_id = club_id_param;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to increment helpful count
CREATE OR REPLACE FUNCTION increment_review_helpful(review_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE club_reviews
    SET helpful_count = helpful_count + 1
    WHERE id = review_id_param;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Triggers
-- ============================================================================

-- Trigger to update club rating when review is added/updated/deleted
CREATE OR REPLACE FUNCTION update_club_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Update club's average rating and total reviews
    UPDATE clubs
    SET 
        rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM club_reviews
            WHERE club_id = COALESCE(NEW.club_id, OLD.club_id)
        ),
        total_reviews = (
            SELECT COUNT(*)
            FROM club_reviews
            WHERE club_id = COALESCE(NEW.club_id, OLD.club_id)
        )
    WHERE id = COALESCE(NEW.club_id, OLD.club_id);
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_update_club_rating_on_insert ON club_reviews;
CREATE TRIGGER trigger_update_club_rating_on_insert
    AFTER INSERT ON club_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_club_rating();

DROP TRIGGER IF EXISTS trigger_update_club_rating_on_update ON club_reviews;
CREATE TRIGGER trigger_update_club_rating_on_update
    AFTER UPDATE ON club_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_club_rating();

DROP TRIGGER IF EXISTS trigger_update_club_rating_on_delete ON club_reviews;
CREATE TRIGGER trigger_update_club_rating_on_delete
    AFTER DELETE ON club_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_club_rating();

-- ============================================================================
-- Sample Data (Optional - for testing)
-- ============================================================================

-- Uncomment to add sample reviews
-- INSERT INTO club_reviews (club_id, user_id, rating, comment)
-- SELECT 
--     (SELECT id FROM clubs LIMIT 1),
--     (SELECT id FROM auth.users LIMIT 1),
--     4.5,
--     'Câu lạc bộ rất tuyệt vời! Cơ sở vật chất hiện đại, nhân viên thân thiện.'
-- WHERE NOT EXISTS (
--     SELECT 1 FROM club_reviews
-- );

-- ============================================================================
-- Verification
-- ============================================================================

-- Verify table creation
SELECT 'club_reviews table created' AS status
WHERE EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'club_reviews'
);

-- Verify RLS policies
SELECT 'RLS policies created' AS status
WHERE EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'club_reviews'
);

-- Verify functions
SELECT 'Helper functions created' AS status
WHERE EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname IN ('get_club_review_stats', 'increment_review_helpful')
);
