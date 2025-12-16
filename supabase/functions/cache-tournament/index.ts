// Supabase Edge Function: Cache Tournament
// Caches tournament data using Deno KV (built-in, free)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { tournamentId } = await req.json();
    
    if (!tournamentId) {
      return new Response(
        JSON.stringify({ error: 'tournamentId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Deno KV (built-in cache)
    const kv = await Deno.openKv();
    
    // Check cache first
    const cacheKey = `tournament:${tournamentId}`;
    const cached = await kv.get([cacheKey]);
    
    if (cached.value) {
      // Cache hit
      return new Response(
        JSON.stringify({ 
          data: cached.value,
          cached: true,
          timestamp: cached.versionstamp 
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Cache miss - fetch from database
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data, error } = await supabaseClient
      .from('tournaments')
      .select('*, tournament_participants(*), matches(*)')
      .eq('id', tournamentId)
      .single();

    if (error) {
      throw error;
    }

    // Cache for 5 minutes (300 seconds)
    await kv.set([cacheKey], data, { expireIn: 300 });

    return new Response(
      JSON.stringify({ 
        data,
        cached: false 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});

