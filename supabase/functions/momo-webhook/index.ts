import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MoMoCallback {
  partnerCode: string
  orderId: string
  requestId: string
  amount: number
  orderInfo: string
  orderType: string
  transId: number
  resultCode: number
  message: string
  payType: string
  responseTime: number
  extraData: string
  signature: string
}

// HMAC SHA256 signature verification
async function verifySignature(data: MoMoCallback, secretKey: string): Promise<boolean> {
  try {
    const rawSignature = `accessKey=${data.partnerCode}&amount=${data.amount}&extraData=${data.extraData}&message=${data.message}&orderId=${data.orderId}&orderInfo=${data.orderInfo}&orderType=${data.orderType}&partnerCode=${data.partnerCode}&payType=${data.payType}&requestId=${data.requestId}&responseTime=${data.responseTime}&resultCode=${data.resultCode}&transId=${data.transId}`
    
    const encoder = new TextEncoder()
    const keyData = encoder.encode(secretKey)
    const messageData = encoder.encode(rawSignature)
    
    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    
    const signature = await crypto.subtle.sign('HMAC', cryptoKey, messageData)
    const hashArray = Array.from(new Uint8Array(signature))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    
    return hashHex === data.signature
  } catch (error) {
    console.error('Error verifying signature:', error)
    return false
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse callback data
    const callbackData: MoMoCallback = await req.json()
    
    console.log('📞 MoMo Callback Received:', {
      orderId: callbackData.orderId,
      resultCode: callbackData.resultCode,
      amount: callbackData.amount,
      transId: callbackData.transId,
    })

    // Get secret key from environment
    const secretKey = Deno.env.get('MOMO_SECRET_KEY')
    if (!secretKey) {
      throw new Error('MOMO_SECRET_KEY not configured')
    }

    // Verify signature
    const isValid = await verifySignature(callbackData, secretKey)
    if (!isValid) {
      console.error('❌ Invalid signature')
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('✅ Signature verified')

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Extract tournament ID from orderId (format: TOUR_tournamentId_timestamp)
    const orderIdParts = callbackData.orderId.split('_')
    const tournamentId = orderIdParts[1]

    // Update payment status based on result code
    if (callbackData.resultCode === 0) {
      // Success - Update payment to verified
      console.log('💰 Payment successful, updating status...')
      
      const { data: payment, error: findError } = await supabase
        .from('tournament_payments')
        .select('*')
        .eq('tournament_id', tournamentId)
        .eq('transaction_reference', callbackData.orderId)
        .maybeSingle()

      if (findError) {
        console.error('Error finding payment:', findError)
        throw findError
      }

      if (!payment) {
        // Create new payment record
        const { error: insertError } = await supabase
          .from('tournament_payments')
          .insert({
            tournament_id: tournamentId,
            user_id: callbackData.extraData || null, // User ID passed in extraData
            amount: callbackData.amount,
            payment_method_type: 'momo',
            transaction_reference: callbackData.orderId,
            status: 'verified',
            verified_at: new Date().toISOString(),
          })

        if (insertError) {
          console.error('Error creating payment:', insertError)
          throw insertError
        }

        console.log('✅ Payment created and verified')
      } else {
        // Update existing payment
        const { error: updateError } = await supabase
          .from('tournament_payments')
          .update({
            status: 'verified',
            verified_at: new Date().toISOString(),
            transaction_reference: callbackData.orderId,
          })
          .eq('id', payment.id)

        if (updateError) {
          console.error('Error updating payment:', updateError)
          throw updateError
        }

        console.log('✅ Payment updated to verified')
      }

      // TODO: Send notification to user
      // TODO: Add user to tournament participants

    } else {
      // Failed - Update payment to rejected
      console.log('❌ Payment failed, updating status...')
      
      const { error: updateError } = await supabase
        .from('tournament_payments')
        .update({
          status: 'rejected',
          rejection_reason: callbackData.message,
        })
        .eq('transaction_reference', callbackData.orderId)

      if (updateError) {
        console.error('Error updating failed payment:', updateError)
      }
    }

    // Return success response to MoMo
    return new Response(
      JSON.stringify({ 
        message: 'OK',
        resultCode: 0,
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Error processing callback:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
