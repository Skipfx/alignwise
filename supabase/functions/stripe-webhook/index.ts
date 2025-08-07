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
        // Create clients
        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
        const stripe = new Stripe(stripeKey);

        // Verify webhook signature
        const signature = req.headers.get('stripe-signature');
        const body = await req.text();
        
        const event = stripe.webhooks.constructEvent(
            body,
            signature!,
            Deno.env.get('STRIPE_WEBHOOK_SECRET')!
        );

        // Handle different event types
        switch (event.type) {
            case 'customer.subscription.created':
            case 'customer.subscription.updated':
                await handleSubscriptionChange(supabase, event.data.object);
                break;
                
            case 'customer.subscription.deleted':
                await handleSubscriptionDeleted(supabase, event.data.object);
                break;
                
            case 'invoice.payment_succeeded':
                await handlePaymentSucceeded(supabase, stripe, event.data.object);
                break;
                
            case 'invoice.payment_failed':
                await handlePaymentFailed(supabase, event.data.object);
                break;

            case 'customer.subscription.trial_will_end':
                await handleTrialWillEnd(supabase, event.data.object);
                break;
        }

        return new Response(JSON.stringify({ received: true }), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json'
            },
            status: 200
        });

    } catch (error) {
        console.error('Webhook error:', error);
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

async function handleSubscriptionChange(supabase: any, subscription: any) {
    try {
        // Find customer in our database
        const { data: customer } = await supabase
            .from('customers')
            .select('id, user_id')
            .eq('stripe_customer_id', subscription.customer)
            .single();

        if (!customer) return;

        // Get the price info to link to our prices table
        const { data: price } = await supabase
            .from('prices')
            .select('id')
            .eq('stripe_price_id', subscription.items.data[0].price.id)
            .single();

        // Update or create subscription record
        await supabase
            .from('subscriptions')
            .upsert({
                customer_id: customer.id,
                stripe_subscription_id: subscription.id,
                status: subscription.status,
                price_id: price?.id,
                trial_start: subscription.trial_start ? new Date(subscription.trial_start * 1000).toISOString() : null,
                trial_end: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
                current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
                current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
                cancel_at_period_end: subscription.cancel_at_period_end,
                canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
                updated_at: new Date().toISOString()
            }, {
                onConflict: 'stripe_subscription_id'
            });

        // Update user role to premium if subscription is active
        if (subscription.status === 'active' || subscription.status === 'trialing') {
            await supabase
                .from('user_profiles')
                .update({ 
                    role: 'premium',
                    updated_at: new Date().toISOString()
                })
                .eq('id', customer.user_id);
        }

    } catch (error) {
        console.error('Error handling subscription change:', error);
        throw error;
    }
}

async function handleSubscriptionDeleted(supabase: any, subscription: any) {
    try {
        // Update subscription status to canceled
        await supabase
            .from('subscriptions')
            .update({ 
                status: 'canceled',
                canceled_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            })
            .eq('stripe_subscription_id', subscription.id);

        // Find customer to update user role
        const { data: customer } = await supabase
            .from('customers')
            .select('user_id')
            .eq('stripe_customer_id', subscription.customer)
            .single();

        if (customer) {
            await supabase
                .from('user_profiles')
                .update({ 
                    role: 'free',
                    updated_at: new Date().toISOString()
                })
                .eq('id', customer.user_id);
        }

    } catch (error) {
        console.error('Error handling subscription deletion:', error);
        throw error;
    }
}

async function handlePaymentSucceeded(supabase: any, stripe: any, invoice: any) {
    try {
        // If this is a subscription payment, update subscription status
        if (invoice.subscription) {
            const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
            await handleSubscriptionChange(supabase, subscription);
        }
    } catch (error) {
        console.error('Error handling payment success:', error);
        throw error;
    }
}

async function handlePaymentFailed(supabase: any, invoice: any) {
    try {
        // Update subscription status to past_due if payment failed
        if (invoice.subscription) {
            await supabase
                .from('subscriptions')
                .update({ 
                    status: 'past_due',
                    updated_at: new Date().toISOString()
                })
                .eq('stripe_subscription_id', invoice.subscription);
        }
    } catch (error) {
        console.error('Error handling payment failure:', error);
        throw error;
    }
}

async function handleTrialWillEnd(supabase: any, subscription: any) {
    try {
        // You could send notifications here or update user preferences
        console.log(`Trial ending soon for subscription: ${subscription.id}`);
        
        // Optional: Update a flag in user_profiles to show trial ending warning
        const { data: customer } = await supabase
            .from('customers')
            .select('user_id')
            .eq('stripe_customer_id', subscription.customer)
            .single();

        if (customer) {
            // You could add a trial_ending_notification field to track this
            console.log(`Trial ending for user: ${customer.user_id}`);
        }
    } catch (error) {
        console.error('Error handling trial will end:', error);
        throw error;
    }
}