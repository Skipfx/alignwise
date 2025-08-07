-- Location: supabase/migrations/20250106055500_subscription_management.sql
-- Schema Analysis: Fresh Supabase project with no existing schema
-- Integration Type: Premium subscription management for wellness app
-- Dependencies: None (first migration)

-- 1. Custom Types
CREATE TYPE public.subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'unpaid');
CREATE TYPE public.payment_method_type AS ENUM ('card', 'sepa', 'bancontact', 'giropay', 'ideal', 'sofort');
CREATE TYPE public.user_role AS ENUM ('admin', 'premium', 'free');

-- 2. Core Tables - User management
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    role public.user_role DEFAULT 'free'::public.user_role,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Subscription Management Tables
-- Customers table for Stripe integration
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    stripe_customer_id TEXT UNIQUE,
    email TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Products table for subscription plans
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_product_id TEXT UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Prices table for subscription pricing
CREATE TABLE public.prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    stripe_price_id TEXT UNIQUE,
    unit_amount INTEGER NOT NULL, -- in cents
    currency TEXT DEFAULT 'aud',
    type TEXT CHECK (type IN ('one_time', 'recurring')) DEFAULT 'recurring',
    interval_type TEXT CHECK (interval_type IN ('day', 'week', 'month', 'year')) DEFAULT 'month',
    interval_count INTEGER DEFAULT 1,
    trial_period_days INTEGER DEFAULT 7,
    active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Subscriptions table for active subscriptions
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    stripe_subscription_id TEXT UNIQUE,
    status public.subscription_status NOT NULL DEFAULT 'trialing',
    price_id UUID REFERENCES public.prices(id),
    quantity INTEGER DEFAULT 1,
    trial_start TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Payment methods table for user payment info
CREATE TABLE public.payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    stripe_payment_method_id TEXT UNIQUE,
    type public.payment_method_type DEFAULT 'card',
    card_brand TEXT,
    card_last4 TEXT,
    card_exp_month INTEGER,
    card_exp_year INTEGER,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Essential Indexes for performance
CREATE INDEX idx_user_profiles_user_id ON public.user_profiles(id);
CREATE INDEX idx_customers_user_id ON public.customers(user_id);
CREATE INDEX idx_customers_stripe_id ON public.customers(stripe_customer_id);
CREATE INDEX idx_subscriptions_customer_id ON public.subscriptions(customer_id);
CREATE INDEX idx_subscriptions_stripe_id ON public.subscriptions(stripe_subscription_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX idx_prices_product_id ON public.prices(product_id);
CREATE INDEX idx_prices_active ON public.prices(active);
CREATE INDEX idx_payment_methods_customer_id ON public.payment_methods(customer_id);

-- 5. Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies using proper patterns

-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for customers
CREATE POLICY "users_manage_own_customers"
ON public.customers
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Subscriptions via customer relationship
CREATE POLICY "users_view_own_subscriptions"
ON public.subscriptions
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.customers c 
        WHERE c.id = subscriptions.customer_id 
        AND c.user_id = auth.uid()
    )
);

-- Pattern 4: Products and prices are publicly readable
CREATE POLICY "products_publicly_readable"
ON public.products
FOR SELECT
TO public
USING (active = TRUE);

CREATE POLICY "prices_publicly_readable"
ON public.prices
FOR SELECT
TO public
USING (active = TRUE);

-- Pattern 2: Payment methods via customer relationship
CREATE POLICY "users_manage_own_payment_methods"
ON public.payment_methods
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.customers c 
        WHERE c.id = payment_methods.customer_id 
        AND c.user_id = auth.uid()
    )
);

-- 7. Functions for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'free')::public.user_role
  );
  RETURN NEW;
END;
$$;

-- Trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. Utility functions for subscription management
CREATE OR REPLACE FUNCTION public.is_premium_user(user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    JOIN public.customers c ON up.id = c.user_id
    JOIN public.subscriptions s ON c.id = s.customer_id
    WHERE up.id = user_uuid 
    AND s.status IN ('active', 'trialing')
    AND (s.current_period_end IS NULL OR s.current_period_end > NOW())
)
$$;

-- Function to check trial status
CREATE OR REPLACE FUNCTION public.is_in_trial(user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    JOIN public.customers c ON up.id = c.user_id
    JOIN public.subscriptions s ON c.id = s.customer_id
    WHERE up.id = user_uuid 
    AND s.status = 'trialing'
    AND s.trial_end > NOW()
)
$$;

-- 9. Mock Data for testing
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    user_uuid UUID := gen_random_uuid();
    customer1_uuid UUID := gen_random_uuid();
    customer2_uuid UUID := gen_random_uuid();
    product_uuid UUID := gen_random_uuid();
    monthly_price_uuid UUID := gen_random_uuid();
    yearly_price_uuid UUID := gen_random_uuid();
    subscription_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users with required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@alignwise.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'user@alignwise.com', crypt('user123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Premium User"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Insert premium product
    INSERT INTO public.products (id, stripe_product_id, name, description) VALUES
        (product_uuid, 'prod_premium_alignwise', 'AlignWise Premium', 'Unlock all premium features including advanced AI coaching, unlimited access, and priority support');

    -- Insert pricing plans (Australian dollars)
    INSERT INTO public.prices (id, product_id, stripe_price_id, unit_amount, currency, interval_type, trial_period_days) VALUES
        (monthly_price_uuid, product_uuid, 'price_monthly_premium_aud', 999, 'aud', 'month', 7), -- $9.99 AUD monthly
        (yearly_price_uuid, product_uuid, 'price_yearly_premium_aud', 7999, 'aud', 'year', 7); -- $79.99 AUD yearly (save 20%)

    -- Create customers
    INSERT INTO public.customers (id, user_id, stripe_customer_id, email) VALUES
        (customer1_uuid, admin_uuid, 'cus_admin_stripe', 'admin@alignwise.com'),
        (customer2_uuid, user_uuid, 'cus_user_stripe', 'user@alignwise.com');

    -- Create active subscription for premium user (trial period)
    INSERT INTO public.subscriptions (id, customer_id, stripe_subscription_id, status, price_id, trial_start, trial_end, current_period_start, current_period_end) VALUES
        (subscription_uuid, customer2_uuid, 'sub_user_premium', 'trialing', monthly_price_uuid, 
         NOW(), NOW() + INTERVAL '7 days', NOW(), NOW() + INTERVAL '1 month');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 10. Cleanup function for testing
CREATE OR REPLACE FUNCTION public.cleanup_subscription_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs for cleanup
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@alignwise.com';

    -- Delete in dependency order (children first)
    DELETE FROM public.subscriptions WHERE customer_id IN (
        SELECT id FROM public.customers WHERE user_id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.payment_methods WHERE customer_id IN (
        SELECT id FROM public.customers WHERE user_id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.customers WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);
    
    -- Clean up products and prices for testing
    DELETE FROM public.prices WHERE stripe_price_id LIKE '%_aud';
    DELETE FROM public.products WHERE stripe_product_id = 'prod_premium_alignwise';

    -- Delete auth.users last
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;