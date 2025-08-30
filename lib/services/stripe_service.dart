import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StripeService {
  static StripeService? _instance;
  String? _publishableKey;

  // Price IDs - these should be set from your Stripe dashboard
  static const String monthlyPriceId =
      'price_1234567890'; // Replace with actual monthly price ID
  static const String yearlyPriceId =
      'price_0987654321'; // Replace with actual yearly price ID

  StripeService._();

  static StripeService get instance {
    _instance ??= StripeService._();
    return _instance!;
  }

  // Static methods for price information
  static String getMonthlyPrice() {
    return 'AU\$9.99'; // Monthly price
  }

  static String getYearlyPrice() {
    return 'AU\$79.99'; // Yearly price
  }

  static String getYearlyMonthlyEquivalent() {
    return 'AU\$6.67'; // Yearly price divided by 12
  }

  static String getSuccessUrl() {
    return 'https://alignwise.app/success';
  }

  static String getCancelUrl() {
    return 'https://alignwise.app/cancel';
  }

  static Future<String> createCheckoutSession({
    required String priceId,
    required String userId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final supabaseClient = Supabase.instance.client;

      final response = await supabaseClient.functions.invoke(
        'create-checkout-session',
        body: {
          'priceId': priceId,
          'userId': userId,
          'successUrl': successUrl ?? getSuccessUrl(),
          'cancelUrl': cancelUrl ?? getCancelUrl(),
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create checkout session: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      return data['url'] as String;
    } catch (e) {
      debugPrint('❌ Checkout session creation failed: $e');
      throw Exception('Checkout session creation failed: $e');
    }
  }

  Future<void> initialize() async {
    try {
      // Load Stripe publishable key from env.json
      final String envString = await rootBundle.loadString('env.json');
      final Map<String, dynamic> env = json.decode(envString);

      _publishableKey = env['STRIPE_PUBLISHABLE_KEY']?.toString();

      if (_publishableKey == null ||
          _publishableKey!.isEmpty ||
          _publishableKey!.contains('your-')) {
        throw Exception('STRIPE_PUBLISHABLE_KEY not configured in env.json');
      }

      debugPrint('✅ Stripe service initialized successfully');
    } catch (e) {
      debugPrint('❌ Stripe initialization failed: $e');
      throw Exception('Stripe initialization failed: $e');
    }
  }

  Future<Map<String, dynamic>> createCheckoutSessionInstance({
    required String priceId,
    required String userId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      if (_publishableKey == null) {
        await initialize();
      }

      final supabaseClient = Supabase.instance.client;

      final response = await supabaseClient.functions.invoke(
        'create-checkout-session',
        body: {
          'priceId': priceId,
          'userId': userId,
          'successUrl': successUrl ?? 'https://alignwise.app/success',
          'cancelUrl': cancelUrl ?? 'https://alignwise.app/cancel',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create checkout session: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Checkout session creation failed: $e');
      throw Exception('Checkout session creation failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final supabaseClient = Supabase.instance.client;

      final response = await supabaseClient.from('products').select('''
            *,
            prices (
              id,
              currency,
              unit_amount,
              interval,
              interval_count,
              type
            )
          ''').eq('active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to get subscription plans: $e');
      throw Exception('Failed to get subscription plans: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentSubscription(String userId) async {
    try {
      final supabaseClient = Supabase.instance.client;

      final response = await supabaseClient.from('subscriptions').select('''
            *,
            prices (
              id,
              currency,
              unit_amount,
              interval,
              products (
                name,
                description
              )
            )
          ''').eq('user_id', userId).eq('status', 'active').maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Failed to get current subscription: $e');
      return null;
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final supabaseClient = Supabase.instance.client;

      final response = await supabaseClient.functions.invoke(
        'manage-subscription',
        body: {
          'subscriptionId': subscriptionId,
          'action': 'cancel',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to cancel subscription: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ Subscription cancellation failed: $e');
      throw Exception('Subscription cancellation failed: $e');
    }
  }

  String? get publishableKey => _publishableKey;
}
