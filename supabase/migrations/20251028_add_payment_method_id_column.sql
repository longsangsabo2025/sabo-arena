-- Add payment_method_id column to tournament_participants
-- Migration: 20251028_add_payment_method_id_to_tournament_participants

-- Add payment_method_id column (nullable, references payment_methods)
ALTER TABLE tournament_participants
ADD COLUMN payment_method_id UUID REFERENCES payment_methods(id) ON DELETE SET NULL;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_tournament_participants_payment_method 
ON tournament_participants(payment_method_id);

-- Add comment
COMMENT ON COLUMN tournament_participants.payment_method_id 
IS 'References the payment method used for tournament registration';
