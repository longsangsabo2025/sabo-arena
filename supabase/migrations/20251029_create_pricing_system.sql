-- =====================================================
-- CLUB PRICING SYSTEM
-- Created: 2025-10-29
-- Purpose: Manage club table rates, membership fees, and additional services
-- =====================================================

-- =====================================================
-- 1. TABLE RATES
-- =====================================================
CREATE TABLE IF NOT EXISTS public.club_table_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    hourly_rate DECIMAL(10,2) NOT NULL CHECK (hourly_rate > 0),
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_club_table_rate_name UNIQUE (club_id, name)
);

-- Index for faster queries
CREATE INDEX idx_club_table_rates_club ON club_table_rates(club_id);
CREATE INDEX idx_club_table_rates_active ON club_table_rates(club_id, is_active);

-- =====================================================
-- 2. MEMBERSHIP FEES
-- =====================================================
CREATE TABLE IF NOT EXISTS public.club_membership_fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    benefits TEXT,
    monthly_fee DECIMAL(10,2) NOT NULL CHECK (monthly_fee >= 0),
    yearly_fee DECIMAL(10,2) NOT NULL CHECK (yearly_fee >= 0),
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_club_membership_name UNIQUE (club_id, name)
);

-- Index for faster queries
CREATE INDEX idx_club_membership_fees_club ON club_membership_fees(club_id);
CREATE INDEX idx_club_membership_fees_active ON club_membership_fees(club_id, is_active);

-- =====================================================
-- 3. ADDITIONAL SERVICES
-- =====================================================
CREATE TABLE IF NOT EXISTS public.club_additional_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    unit VARCHAR(50) DEFAULT 'lần',
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_club_service_name UNIQUE (club_id, name)
);

-- Index for faster queries
CREATE INDEX idx_club_additional_services_club ON club_additional_services(club_id);
CREATE INDEX idx_club_additional_services_active ON club_additional_services(club_id, is_active);

-- =====================================================
-- 4. TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Trigger for table_rates
CREATE OR REPLACE FUNCTION update_club_table_rates_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_club_table_rates
    BEFORE UPDATE ON club_table_rates
    FOR EACH ROW
    EXECUTE FUNCTION update_club_table_rates_timestamp();

-- Trigger for membership_fees
CREATE OR REPLACE FUNCTION update_club_membership_fees_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_club_membership_fees
    BEFORE UPDATE ON club_membership_fees
    FOR EACH ROW
    EXECUTE FUNCTION update_club_membership_fees_timestamp();

-- Trigger for additional_services
CREATE OR REPLACE FUNCTION update_club_additional_services_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_club_additional_services
    BEFORE UPDATE ON club_additional_services
    FOR EACH ROW
    EXECUTE FUNCTION update_club_additional_services_timestamp();

-- =====================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE club_table_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_membership_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_additional_services ENABLE ROW LEVEL SECURITY;

-- Public can view active pricing
CREATE POLICY "Anyone can view active table rates"
    ON club_table_rates FOR SELECT
    USING (is_active = true);

CREATE POLICY "Anyone can view active membership fees"
    ON club_membership_fees FOR SELECT
    USING (is_active = true);

CREATE POLICY "Anyone can view active services"
    ON club_additional_services FOR SELECT
    USING (is_active = true);

-- Club owners can manage their pricing (all operations)
CREATE POLICY "Club owners can manage table rates"
    ON club_table_rates FOR ALL
    USING (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    )
    WITH CHECK (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "Club owners can manage membership fees"
    ON club_membership_fees FOR ALL
    USING (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    )
    WITH CHECK (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "Club owners can manage services"
    ON club_additional_services FOR ALL
    USING (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    )
    WITH CHECK (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    );

-- =====================================================
-- 6. HELPER FUNCTIONS
-- =====================================================

-- Get all pricing for a club
CREATE OR REPLACE FUNCTION get_club_pricing(p_club_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'table_rates', (
            SELECT COALESCE(json_agg(json_build_object(
                'id', id,
                'name', name,
                'description', description,
                'hourlyRate', hourly_rate,
                'isActive', is_active
            ) ORDER BY display_order, name), '[]'::json)
            FROM club_table_rates
            WHERE club_id = p_club_id
        ),
        'membership_fees', (
            SELECT COALESCE(json_agg(json_build_object(
                'id', id,
                'name', name,
                'benefits', benefits,
                'monthlyFee', monthly_fee,
                'yearlyFee', yearly_fee,
                'isActive', is_active
            ) ORDER BY display_order, name), '[]'::json)
            FROM club_membership_fees
            WHERE club_id = p_club_id
        ),
        'additional_services', (
            SELECT COALESCE(json_agg(json_build_object(
                'id', id,
                'name', name,
                'description', description,
                'price', price,
                'unit', unit,
                'isActive', is_active
            ) ORDER BY display_order, name), '[]'::json)
            FROM club_additional_services
            WHERE club_id = p_club_id
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. COMMENTS
-- =====================================================
COMMENT ON TABLE club_table_rates IS 'Stores hourly rates for different table types';
COMMENT ON TABLE club_membership_fees IS 'Stores membership fee plans';
COMMENT ON TABLE club_additional_services IS 'Stores additional services and their prices';

COMMENT ON FUNCTION get_club_pricing IS 'Returns all pricing information for a club in JSON format';

-- =====================================================
-- Migration Complete
-- =====================================================
