-- Add verification document columns to clubs table
ALTER TABLE public.clubs 
ADD COLUMN IF NOT EXISTS business_license_url text,
ADD COLUMN IF NOT EXISTS identity_card_url text;

-- Add comment
COMMENT ON COLUMN public.clubs.business_license_url IS 'URL to the business license image';
COMMENT ON COLUMN public.clubs.identity_card_url IS 'URL to the identity card/CCCD image';
