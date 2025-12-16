-- =====================================================
-- Add missing columns to transactions table
-- =====================================================

-- Add type column for categorizing transactions
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS type TEXT;

-- Add description column for human-readable messages
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS description TEXT;

-- Add reference columns to link transactions to source entities
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS reference_type TEXT;

ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS reference_id UUID;

-- Add timestamp if missing
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_reference ON public.transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at DESC);

-- Add comment
COMMENT ON COLUMN public.transactions.type IS 'Transaction type: tournament_prize, spa_purchase, reward, refund, etc';
COMMENT ON COLUMN public.transactions.description IS 'Human-readable transaction description';
COMMENT ON COLUMN public.transactions.reference_type IS 'Source entity type: tournament, challenge, etc';
COMMENT ON COLUMN public.transactions.reference_id IS 'Source entity ID';
