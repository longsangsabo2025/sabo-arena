-- =====================================================
-- TOURNAMENT RESULT HISTORY TABLE
-- Store complete snapshot of tournament completion results
-- =====================================================

CREATE TABLE IF NOT EXISTS public.tournament_result_history (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Tournament Reference
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  tournament_name TEXT NOT NULL,
  tournament_format TEXT NOT NULL, -- 'single_elimination', 'double_elimination', 'sabo_de16', etc.
  
  -- Completion Info
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_by UUID REFERENCES public.users(id), -- Admin who clicked "Complete"
  
  -- Tournament Stats
  total_participants INT NOT NULL,
  total_matches INT NOT NULL,
  prize_pool_vnd INT DEFAULT 0,
  
  -- Results Summary (JSONB for flexibility)
  standings JSONB NOT NULL, -- Array of {participant_id, participant_name, position, final_elo, wins, losses}
  
  -- ELO Changes (JSONB)
  elo_updates JSONB NOT NULL, -- Array of {user_id, username, old_elo, new_elo, change, reason}
  
  -- SPA Distribution (JSONB)
  spa_distribution JSONB NOT NULL, -- Array of {user_id, username, position, bonus_spa, total_spa_after}
  
  -- Prize Distribution (JSONB)
  prize_distribution JSONB, -- Array of {user_id, username, position, prize_amount_vnd, percentage}
  
  -- Voucher Issuance (JSONB)
  vouchers_issued JSONB, -- Array of {user_id, username, voucher_code, type, value}
  
  -- Processing Flags
  elo_updated BOOLEAN DEFAULT FALSE,
  spa_distributed BOOLEAN DEFAULT FALSE,
  prizes_recorded BOOLEAN DEFAULT FALSE,
  vouchers_issued_flag BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  options JSONB, -- {updateElo: true, distributePrizes: true, issueVouchers: true}
  errors JSONB, -- Any errors that occurred during processing
  processing_time_ms INT, -- How long it took to complete
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_tournament_result_history_tournament_id 
  ON public.tournament_result_history(tournament_id);

CREATE INDEX IF NOT EXISTS idx_tournament_result_history_completed_at 
  ON public.tournament_result_history(completed_at DESC);

CREATE INDEX IF NOT EXISTS idx_tournament_result_history_completed_by 
  ON public.tournament_result_history(completed_by);

-- GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_tournament_result_history_standings 
  ON public.tournament_result_history USING GIN (standings);

CREATE INDEX IF NOT EXISTS idx_tournament_result_history_elo_updates 
  ON public.tournament_result_history USING GIN (elo_updates);

-- =====================================================
-- RLS POLICIES
-- =====================================================

ALTER TABLE public.tournament_result_history ENABLE ROW LEVEL SECURITY;

-- Admin can view all
CREATE POLICY "Admin can view all tournament results"
  ON public.tournament_result_history
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Admin can insert
CREATE POLICY "Admin can insert tournament results"
  ON public.tournament_result_history
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Users can view their own tournament results
CREATE POLICY "Users can view their tournament results"
  ON public.tournament_result_history
  FOR SELECT
  TO authenticated
  USING (
    standings @> jsonb_build_array(
      jsonb_build_object('participant_id', auth.uid()::text)
    )
  );

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE public.tournament_result_history IS 
  'Complete audit trail of all tournament completion results including ELO, SPA, prizes, and vouchers';

COMMENT ON COLUMN public.tournament_result_history.standings IS 
  'Final standings with positions, wins, losses. Format: [{participant_id, participant_name, position, final_elo, wins, losses, ...}]';

COMMENT ON COLUMN public.tournament_result_history.elo_updates IS 
  'All ELO changes applied. Format: [{user_id, username, old_elo, new_elo, change, reason}]';

COMMENT ON COLUMN public.tournament_result_history.spa_distribution IS 
  'SPA bonuses distributed. Format: [{user_id, username, position, bonus_spa, balance_before, balance_after}]';

COMMENT ON COLUMN public.tournament_result_history.prize_distribution IS 
  'Prize money distribution. Format: [{user_id, username, position, amount_vnd, percentage}]';

COMMENT ON COLUMN public.tournament_result_history.vouchers_issued IS 
  'Vouchers issued to winners. Format: [{user_id, username, voucher_code, type, value, expires_at}]';

COMMENT ON COLUMN public.tournament_result_history.processing_time_ms IS 
  'Total time taken to complete tournament processing in milliseconds';

-- =====================================================
-- EXAMPLE QUERY: Get tournament completion summary
-- =====================================================

/*
SELECT 
  t.name as tournament_name,
  trh.completed_at,
  trh.total_participants,
  trh.total_matches,
  trh.prize_pool_vnd,
  trh.elo_updated,
  trh.spa_distributed,
  trh.prizes_recorded,
  trh.processing_time_ms,
  jsonb_array_length(trh.standings) as num_final_standings,
  jsonb_array_length(trh.elo_updates) as num_elo_updates,
  jsonb_array_length(trh.spa_distribution) as num_spa_bonuses
FROM tournament_result_history trh
JOIN tournaments t ON t.id = trh.tournament_id
ORDER BY trh.completed_at DESC
LIMIT 10;
*/

-- =====================================================
-- EXAMPLE QUERY: Get specific user's tournament results
-- =====================================================

/*
SELECT 
  trh.tournament_name,
  trh.completed_at,
  s.value->>'position' as position,
  s.value->>'final_elo' as final_elo,
  s.value->>'wins' as wins,
  s.value->>'losses' as losses,
  e.value->>'change' as elo_change,
  sp.value->>'bonus_spa' as spa_bonus,
  p.value->>'amount_vnd' as prize_vnd
FROM tournament_result_history trh
CROSS JOIN LATERAL jsonb_array_elements(trh.standings) s
LEFT JOIN LATERAL jsonb_array_elements(trh.elo_updates) e 
  ON e.value->>'user_id' = s.value->>'participant_id'
LEFT JOIN LATERAL jsonb_array_elements(trh.spa_distribution) sp 
  ON sp.value->>'user_id' = s.value->>'participant_id'
LEFT JOIN LATERAL jsonb_array_elements(trh.prize_distribution) p 
  ON p.value->>'user_id' = s.value->>'participant_id'
WHERE s.value->>'participant_id' = 'USER_ID_HERE'
ORDER BY trh.completed_at DESC;
*/
