import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/stripe_service.dart';
import './widgets/premium_features_widget.dart';
import './widgets/pricing_plans_widget.dart';
import './widgets/subscription_header_widget.dart';

class PremiumUpgrade extends StatefulWidget {
  const PremiumUpgrade({super.key});

  @override
  State<PremiumUpgrade> createState() => _PremiumUpgradeState();
}

class _PremiumUpgradeState extends State<PremiumUpgrade> {
  bool _isLoading = false;
  bool _isYearly = false;
  late WebViewController? _webViewController;
  final _authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SubscriptionHeaderWidget(onClose: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    _buildHeroSection(),
                    SizedBox(height: 4.h),
                    PremiumFeaturesWidget(),
                    SizedBox(height: 4.h),
                    PricingPlansWidget(
                      isYearly: _isYearly,
                      onToggle: (value) => setState(() => _isYearly = value),
                    ),
                    SizedBox(height: 4.h),
                    _buildUpgradeButton(),
                    SizedBox(height: 2.h),
                    _buildTrialInfo(),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryLight, AppTheme.primaryVariantLight],
        ),
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'workspace_premium',
            color: Colors.white,
            size: 12.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Unlock Premium Features',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Take your wellness journey to the next level with advanced AI coaching and unlimited access',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 2,
        ),
        child:
            _isLoading
                ? SizedBox(
                  height: 3.h,
                  width: 3.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'upgrade',
                      color: Colors.white,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Upgrade Now',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildTrialInfo() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.successLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: AppTheme.successLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'info',
            color: AppTheme.successLight,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7-Day Free Trial',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.successLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cancel anytime during your free trial. No charges until trial ends.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);

    try {
      if (!_authService.isAuthenticated) {
        _showError('Please sign in to upgrade to premium.');
        return;
      }

      final priceId =
          _isYearly
              ? StripeService.yearlyPriceId
              : StripeService.monthlyPriceId;
      final successUrl = StripeService.getSuccessUrl();
      final cancelUrl = StripeService.getCancelUrl();

      final checkoutUrl = await StripeService.createCheckoutSession(
        priceId: priceId,
        userId: _authService.currentUserId!,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      _showPaymentWebView(checkoutUrl);
    } catch (e) {
      _showError(
        'Payment setup failed. Please check your connection and try again.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPaymentWebView(String checkoutUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: 90.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.w),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Complete Payment',
                        style: AppTheme.lightTheme.textTheme.titleLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: WebViewWidget(
                    controller:
                        WebViewController()
                          ..setJavaScriptMode(JavaScriptMode.unrestricted)
                          ..setNavigationDelegate(
                            NavigationDelegate(
                              onNavigationRequest: (request) {
                                if (request.url.contains('payment-success')) {
                                  Navigator.pop(context);
                                  _handlePaymentSuccess();
                                  return NavigationDecision.prevent;
                                }
                                if (request.url.contains('payment-cancel')) {
                                  Navigator.pop(context);
                                  _handlePaymentCancel();
                                  return NavigationDecision.prevent;
                                }
                                return NavigationDecision.navigate;
                              },
                            ),
                          )
                          ..loadRequest(Uri.parse(checkoutUrl)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _handlePaymentSuccess() {
    Fluttertoast.showToast(
      msg: "🎉 Welcome to Premium! Enjoy unlimited access to all features.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: AppTheme.successLight,
      textColor: Colors.white,
    );

    // Navigate back to profile with success flag
    Navigator.pop(context, true);
  }

  void _handlePaymentCancel() {
    Fluttertoast.showToast(
      msg: "Payment cancelled. You can upgrade anytime from your profile.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.warningLight,
      textColor: Colors.white,
    );
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.errorLight,
      textColor: Colors.white,
    );
  }
}
