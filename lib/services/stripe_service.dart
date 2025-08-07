import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class StripeService {
  static const String _baseUrl =
      'https://your-project.supabase.co/functions/v1';

  // Australian Dollar pricing - Updated for $9.99 AUD monthly
  static const String monthlyPriceId = 'price_monthly_premium_aud';
  static const String yearlyPriceId = 'price_yearly_premium_aud';

  // Price values in cents (Australian dollars)
  static const int monthlyPriceCents = 999; // $9.99 AUD
  static const int yearlyPriceCents = 7999; // $79.99 AUD (save 20%)

  static Future<String?> createCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/create-checkout-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: json.encode({
          'priceId': priceId,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        }),
      );

      developer
          .log('Stripe Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'] as String?;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['error'] ?? 'Failed to create checkout session');
      }
    } catch (e) {
      developer.log('Error creating checkout session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('subscriptions')
          .select('''
            *,
            customers!inner(user_id),
            prices(unit_amount, currency, interval_type)
          ''')
          .eq('customers.user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      developer.log('Error fetching subscription status: $e');
      return null;
    }
  }

  static Future<bool> cancelSubscription() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/cancel-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error canceling subscription: $e');
      return false;
    }
  }

  static String getSuccessUrl() {
    return 'https://alignwise.com/payment-success';
  }

  static String getCancelUrl() {
    return 'https://alignwise.com/payment-cancel';
  }

  // Helper methods for Australian dollar formatting
  static String formatAudPrice(int cents) {
    return 'AU\$${(cents / 100).toStringAsFixed(2)}';
  }

  static String getMonthlyPrice() {
    return formatAudPrice(monthlyPriceCents);
  }

  static String getYearlyPrice() {
    return formatAudPrice(yearlyPriceCents);
  }

  static String getYearlyMonthlyEquivalent() {
    final monthlyEquivalent = (yearlyPriceCents / 12).round();
    return formatAudPrice(monthlyEquivalent);
  }

  static bool isSubscriptionActive(Map<String, dynamic>? subscription) {
    if (subscription == null) return false;

    final status = subscription['status'] as String?;
    return status == 'active' || status == 'trialing';
  }

  static bool isInTrial(Map<String, dynamic>? subscription) {
    if (subscription == null) return false;

    final status = subscription['status'] as String?;
    final trialEnd = subscription['trial_end'] as String?;

    if (status == 'trialing' && trialEnd != null) {
      final trialEndDate = DateTime.parse(trialEnd);
      return DateTime.now().isBefore(trialEndDate);
    }

    return false;
  }

  static int getDaysLeftInTrial(Map<String, dynamic>? subscription) {
    if (!isInTrial(subscription)) return 0;

    final trialEnd = subscription!['trial_end'] as String;
    final trialEndDate = DateTime.parse(trialEnd);
    final now = DateTime.now();

    return trialEndDate.difference(now).inDays;
  }

  static DateTime? getCurrentPeriodEnd(Map<String, dynamic>? subscription) {
    if (subscription == null) return null;

    final periodEnd = subscription['current_period_end'] as String?;
    return periodEnd != null ? DateTime.parse(periodEnd) : null;
  }

  // Check if user has premium access
  static Future<bool> hasPremiumAccess() async {
    final subscription = await getSubscriptionStatus();
    return isSubscriptionActive(subscription);
  }

  // Get subscription info for display
  static Future<Map<String, dynamic>?> getSubscriptionDisplayInfo() async {
    final subscription = await getSubscriptionStatus();
    if (subscription == null) return null;

    final prices = subscription['prices'] as Map<String, dynamic>?;
    final unitAmount = prices?['unit_amount'] as int? ?? 0;
    final currency = prices?['currency'] as String? ?? 'aud';
    final intervalType = prices?['interval_type'] as String? ?? 'month';

    return {
      'status': subscription['status'],
      'is_active': isSubscriptionActive(subscription),
      'is_trial': isInTrial(subscription),
      'trial_days_left': getDaysLeftInTrial(subscription),
      'price': formatAudPrice(unitAmount),
      'interval': intervalType,
      'current_period_end': getCurrentPeriodEnd(subscription),
      'cancel_at_period_end': subscription['cancel_at_period_end'] ?? false,
    };
  }
}