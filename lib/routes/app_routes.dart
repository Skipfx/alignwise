import 'package:flutter/material.dart';
import '../presentation/nutrition_tracking/nutrition_tracking.dart';
import '../presentation/mindfulness_hub/mindfulness_hub.dart';
import '../presentation/meditation_session/meditation_session.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/challenges_hub/challenges_hub.dart';
import '../presentation/barcode_scanner/barcode_scanner.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/fitness_tracking/fitness_tracking.dart';
import '../presentation/workout_session/workout_session.dart';
import '../presentation/dashboard_home/dashboard_home.dart';
import '../presentation/macro_tracking_dashboard/macro_tracking_dashboard.dart';
import '../presentation/meal_library/meal_library.dart';
import '../presentation/premium_upgrade/premium_upgrade.dart';
import '../presentation/fitness_programs/fitness_programs.dart';
import '../presentation/achievement_gallery/achievement_gallery.dart';
import '../presentation/community_feed/community_feed.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String nutritionTracking = '/nutrition-tracking';
  static const String mindfulnessHub = '/mindfulness-hub';
  static const String meditationSession = '/meditation-session';
  static const String splash = '/splash-screen';
  static const String challengesHub = '/challenges-hub';
  static const String barcodeScanner = '/barcode-scanner';
  static const String userProfile = '/user-profile';
  static const String authentication = '/authentication-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String fitnessTracking = '/fitness-tracking';
  static const String workoutSession = '/workout-session';
  static const String dashboardHome = '/dashboard-home';
  static const String macroTrackingDashboard = '/macro-tracking-dashboard';
  static const String mealLibrary = '/meal-library';
  static const String premiumUpgrade = '/premium-upgrade';
  static const String fitnessPrograms = '/fitness-programs';
  static const String achievementGallery = '/achievement-gallery';
  static const String communityFeed = '/community-feed';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    nutritionTracking: (context) => const NutritionTracking(),
    mindfulnessHub: (context) => const MindfulnessHub(),
    meditationSession: (context) => const MeditationSession(),
    splash: (context) => const SplashScreen(),
    challengesHub: (context) => const ChallengesHub(),
    barcodeScanner: (context) => const BarcodeScanner(),
    userProfile: (context) => const UserProfile(),
    authentication: (context) => const AuthenticationScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    fitnessTracking: (context) => const FitnessTracking(),
    workoutSession: (context) => const WorkoutSession(),
    dashboardHome: (context) => const DashboardHome(),
    macroTrackingDashboard: (context) => const MacroTrackingDashboard(),
    mealLibrary: (context) => const MealLibrary(),
    premiumUpgrade: (context) => const PremiumUpgrade(),
    fitnessPrograms: (context) => const FitnessPrograms(),
    achievementGallery: (context) => const AchievementGallery(),
    communityFeed: (context) => const CommunityFeed(),
    // TODO: Add your other routes here
  };
}
