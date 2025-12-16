-- Add payment_method_id column to tournament_participants table
-- This stores the UUID of the payment method selected during registration

ALTER TABLE public.tournament_participants 
ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_tournament_participants_payment_method 
ON public.tournament_participants(payment_method_id);

-- Update comment
COMMENT ON COLUMN public.tournament_participants.payment_method_id 
IS 'FK to payment_methods table - stores which payment method was used for registration';
