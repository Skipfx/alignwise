import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0';
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

serve(async (req) => {
    // Handle CORS preflight request
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: corsHeaders
        });
    }

    try {
        // Create a Supabase client
        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY');
        const supabase = createClient(supabaseUrl, supabaseKey);

        // Create a Stripe client
        const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
        const stripe = new Stripe(stripeKey);

        // Get the request body
        const { priceId, successUrl, cancelUrl } = await req.json();
        
        // Verify user authentication
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            throw new Error('Authorization header missing');
        }
        
        const token = authHeader.replace('Bearer ', '');
        const { data: { user }, error } = await supabase.auth.getUser(token);
        if (error || !user) {
            throw new Error('Unauthorized');
        }

        // Get or create customer
        let customer = null;
        const { data: existingCustomer } = await supabase
            .from('customers')
            .select('stripe_customer_id')
            .eq('user_id', user.id)
            .single();

        if (existingCustomer?.stripe_customer_id) {
            customer = await stripe.customers.retrieve(existingCustomer.stripe_customer_id);
        } else {
            // Create new customer
            customer = await stripe.customers.create({
                email: user.email,
                metadata: {
                    supabase_user_id: user.id
                }
            });

            // Save customer to database
            await supabase.from('customers').insert({
                user_id: user.id,
                stripe_customer_id: customer.id,
                email: user.email
            });
        }

        // Create a Stripe checkout session for AUD pricing
        const session = await stripe.checkout.sessions.create({
            customer: customer.id,
            payment_method_types: ['card'],
            line_items: [{
                price: priceId, // Will use AUD price IDs: price_monthly_premium_aud or price_yearly_premium_aud
                quantity: 1,
            }],
            mode: 'subscription',
            success_url: successUrl,
            cancel_url: cancelUrl,
            trial_period_days: 7, // 7-day free trial
            currency: 'aud', // Set to Australian dollars
            locale: 'en-AU',
            metadata: {
                supabase_user_id: user.id
            }
        });

        // Return the Stripe checkout session
        return new Response(JSON.stringify({
            url: session.url,
            sessionId: session.id
        }), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json'
            },
            status: 200
        });

    } catch (error) {
        return new Response(JSON.stringify({
            error: error.message
        }), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json'
            },
            status: 400
        });
    }
});