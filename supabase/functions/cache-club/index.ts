// Supabase Edge Function: Cache Club Data
// Caches club data using Deno KV (built-in, free)

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
    const { clubId } = await req.json();
    
    if (!clubId) {
      return new Response(
        JSON.stringify({ error: 'clubId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Deno KV (built-in cache)
    const kv = await Deno.openKv();
    
    // Check cache first
    const cacheKey = `club:${clubId}`;
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
      .from('clubs')
      .select('*')
      .eq('id', clubId)
      .single();

    if (error) {
      throw error;
    }

    // Cache for 15 minutes (900 seconds)
    await kv.set([cacheKey], data, { expireIn: 900 });

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

