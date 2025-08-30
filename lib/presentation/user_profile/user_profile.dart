import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/wellness_service.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/stats_overview_widget.dart';
import './widgets/subscription_card_widget.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final AuthService _authService = AuthService.instance;
  final WellnessService _wellnessService = WellnessService.instance;

  // User data loaded from Supabase
  Map<String, dynamic>? userData;
  Map<String, dynamic>? statsData;
  Map<String, dynamic>? subscriptionData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      if (!_authService.isAuthenticated) {
        setState(() {
          error = "Please log in to view your profile";
          isLoading = false;
        });
        return;
      }

      // Load user profile data - this is the main issue
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) {
        throw Exception("Unable to load user profile");
      }

      // Check if user profile exists in database, if not create one
      if (userProfile.isEmpty || userProfile['full_name'] == null) {
        // Create/update user profile from auth user metadata
        final authUser = _authService.currentUser;
        if (authUser != null) {
          try {
            await _authService.updateUserProfile(
              fullName: authUser.userMetadata?['full_name'] ??
                  authUser.email?.split('@').first ??
                  'User',
            );
            // Reload profile after creation
            final updatedProfile = await _authService.getCurrentUserProfile();
            if (updatedProfile != null) {
              userProfile.addAll(updatedProfile);
            }
          } catch (e) {
            debugPrint('Failed to create/update profile: $e');
          }
        }
      }

      // Load user stats and achievements
      final achievementSummary = await _wellnessService.getAchievementSummary();
      final weeklyWorkoutStats = await _wellnessService.getWeeklyWorkoutStats();
      final totalMeditations = await _wellnessService.getMeditations();

      // Calculate wellness level and progress (simple algorithm based on stats)
      int totalWorkouts = weeklyWorkoutStats['total_workouts'] ?? 0;
      int totalMeditationMinutes = totalMeditations.fold<int>(
          0,
          (sum, meditation) =>
              sum + ((meditation['duration_minutes'] as int?) ?? 0));

      // Simple wellness level calculation (can be enhanced)
      int wellnessLevel = ((totalWorkouts / 20).floor() +
              (totalMeditationMinutes / 300).floor())
          .clamp(1, 10);
      double levelProgress = ((totalWorkouts % 20) / 20.0).clamp(0.0, 1.0);

      setState(() {
        userData = {
          "name": userProfile['full_name'] ??
              _authService.currentUser?.userMetadata?['full_name'] ??
              _authService.currentUser?.email
                  ?.split('@')
                  .first
                  .split('.')
                  .map((e) =>
                      e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
                  .join(' ') ??
              'User',
          "email":
              userProfile['email'] ?? _authService.currentUser?.email ?? '',
          "avatar": userProfile['avatar_url'] ??
              "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
          "wellnessLevel": wellnessLevel,
          "levelProgress": levelProgress,
        };

        statsData = {
          "totalWorkouts": totalWorkouts,
          "meditationMinutes": totalMeditationMinutes,
          "challengesCompleted":
              achievementSummary['completed_achievements'] ?? 0,
          "currentStreak":
              _calculateCurrentStreak(totalWorkouts, totalMeditationMinutes),
          "recentAchievements": _formatRecentAchievements(
              achievementSummary['recent_achievements'] ?? []),
        };

        // Check subscription status (mock for now as premium logic exists but may not be fully implemented)
        subscriptionData = {
          "isPremium": userProfile['role'] == 'premium',
          "planName":
              userProfile['role'] == 'premium' ? "Premium Plan" : "Free Plan",
          "nextBilling": userProfile['role'] == 'premium'
              ? "Next billing in 30 days"
              : "Upgrade to Premium",
          "amount": userProfile['role'] == 'premium' ? "\$9.99/month" : "Free",
        };

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load profile: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  int _calculateCurrentStreak(int workouts, int meditationMinutes) {
    // Simple streak calculation - can be enhanced with actual date-based logic
    return ((workouts / 3) + (meditationMinutes / 60)).floor().clamp(0, 365);
  }

  List<Map<String, dynamic>> _formatRecentAchievements(
      List<dynamic> achievements) {
    return achievements.take(2).map<Map<String, dynamic>>((achievement) {
      final definition = achievement['achievement_definitions'] ?? {};
      return {
        "title": definition['title'] ?? 'Achievement',
        "description": definition['description'] ?? 'Great work!',
        "icon": _mapBadgeRarityToIcon(definition['badge_rarity']),
        "date": _formatDate(achievement['completed_at']),
        "color": _mapBadgeRarityToColor(definition['badge_rarity']),
      };
    }).toList();
  }

  String _mapBadgeRarityToIcon(String? rarity) {
    switch (rarity) {
      case 'legendary':
        return 'stars';
      case 'epic':
        return 'military_tech';
      case 'rare':
        return 'psychology';
      default:
        return 'emoji_events';
    }
  }

  Color _mapBadgeRarityToColor(String? rarity) {
    switch (rarity) {
      case 'legendary':
        return AppTheme.warningLight;
      case 'epic':
        return AppTheme.successLight;
      case 'rare':
        return AppTheme.accentLight;
      default:
        return AppTheme.primaryLight;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Recently';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() == 1 ? '' : 's'} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/authentication',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorLight,
              ),
              SizedBox(height: 2.h),
              Text(
                error!,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppTheme.errorLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ProfileHeaderWidget(userData: userData!),
              StatsOverviewWidget(statsData: statsData!),
              _buildPersonalInformationSection(),
              _buildHealthGoalsSection(),
              _buildAppPreferencesSection(),
              SubscriptionCardWidget(subscriptionData: subscriptionData!),
              _buildAccountSettingsSection(),
              SizedBox(height: 10.h), // Bottom padding for navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInformationSection() {
    final List<Map<String, dynamic>> personalItems = [
      {
        "title": "Edit Profile",
        "subtitle": "Update your personal information",
        "icon": "person",
        "iconColor": AppTheme.primaryLight,
        "type": "navigation",
        "route": "/user-profile",
      },
      {
        "title": "Age",
        "subtitle": "Not specified",
        "icon": "cake",
        "iconColor": AppTheme.secondaryLight,
        "type": "selection",
        "selectedValue": "Not set",
      },
      {
        "title": "Height & Weight",
        "subtitle": "Not specified",
        "icon": "straighten",
        "iconColor": AppTheme.accentLight,
        "type": "selection",
        "selectedValue": "Not set",
      },
      {
        "title": "Activity Level",
        "subtitle": "Moderately Active",
        "icon": "directions_run",
        "iconColor": AppTheme.warningLight,
        "type": "selection",
        "selectedValue": "Moderate",
      },
    ];

    return SettingsSectionWidget(
      title: "Personal Information",
      items: personalItems,
      onSettingChanged: _handleSettingChange,
    );
  }

  Widget _buildHealthGoalsSection() {
    final List<Map<String, dynamic>> healthItems = [
      {
        "title": "Daily Calorie Goal",
        "subtitle": "2,200 calories per day",
        "icon": "local_fire_department",
        "iconColor": AppTheme.errorLight,
        "type": "selection",
        "selectedValue": "2,200",
      },
      {
        "title": "Step Count Target",
        "subtitle": "10,000 steps daily",
        "icon": "directions_walk",
        "iconColor": AppTheme.primaryLight,
        "type": "selection",
        "selectedValue": "10,000",
      },
      {
        "title": "Water Intake Goal",
        "subtitle": "8 glasses per day",
        "icon": "water_drop",
        "iconColor": AppTheme.accentLight,
        "type": "selection",
        "selectedValue": "8 glasses",
      },
      {
        "title": "Mindfulness Minutes",
        "subtitle": "15 minutes daily",
        "icon": "self_improvement",
        "iconColor": AppTheme.secondaryLight,
        "type": "selection",
        "selectedValue": "15 min",
      },
      {
        "title": "Unit System",
        "subtitle": "Imperial (lbs, ft, °F)",
        "icon": "straighten",
        "iconColor": AppTheme.warningLight,
        "type": "selection",
        "selectedValue": "Imperial",
      },
    ];

    return SettingsSectionWidget(
      title: "Health Goals",
      items: healthItems,
      onSettingChanged: _handleSettingChange,
    );
  }

  Widget _buildAppPreferencesSection() {
    final List<Map<String, dynamic>> preferenceItems = [
      {
        "title": "Push Notifications",
        "subtitle": "Workout reminders and achievements",
        "icon": "notifications",
        "iconColor": AppTheme.primaryLight,
        "type": "toggle",
        "value": true,
        "key": "pushNotifications",
      },
      {
        "title": "Workout Reminders",
        "subtitle": "Daily at 7:00 AM",
        "icon": "alarm",
        "iconColor": AppTheme.warningLight,
        "type": "toggle",
        "value": true,
        "key": "workoutReminders",
      },
      {
        "title": "Meditation Reminders",
        "subtitle": "Daily at 9:00 PM",
        "icon": "bedtime",
        "iconColor": AppTheme.accentLight,
        "type": "toggle",
        "value": false,
        "key": "meditationReminders",
      },
      {
        "title": "Water Intake Reminders",
        "subtitle": "Every 2 hours",
        "icon": "water_drop",
        "iconColor": AppTheme.secondaryLight,
        "type": "toggle",
        "value": true,
        "key": "waterReminders",
      },
      {
        "title": "Data Sharing",
        "subtitle": "Share anonymous usage data",
        "icon": "share",
        "iconColor": AppTheme.primaryLight,
        "type": "toggle",
        "value": false,
        "key": "dataSharing",
      },
      {
        "title": "Biometric Authentication",
        "subtitle": "Use Face ID or fingerprint",
        "icon": "fingerprint",
        "iconColor": AppTheme.successLight,
        "type": "navigation",
        "action": "biometric",
      },
    ];

    return SettingsSectionWidget(
      title: "App Preferences",
      items: preferenceItems,
      onSettingChanged: _handleSettingChange,
    );
  }

  Widget _buildAccountSettingsSection() {
    final List<Map<String, dynamic>> accountItems = [
      {
        "title": "Privacy Policy",
        "subtitle": "Read our privacy policy",
        "icon": "privacy_tip",
        "iconColor": AppTheme.primaryLight,
        "type": "navigation",
        "route": "/user-profile",
      },
      {
        "title": "Terms of Service",
        "subtitle": "View terms and conditions",
        "icon": "description",
        "iconColor": AppTheme.accentLight,
        "type": "navigation",
        "route": "/user-profile",
      },
      {
        "title": "Export Data",
        "subtitle": "Download your wellness data",
        "icon": "download",
        "iconColor": AppTheme.secondaryLight,
        "type": "navigation",
        "action": "exportData",
      },
      {
        "title": "Help & Support",
        "subtitle": "Get help or contact support",
        "icon": "help",
        "iconColor": AppTheme.warningLight,
        "type": "navigation",
        "route": "/user-profile",
      },
      {
        "title": "Rate AlignWise",
        "subtitle": "Share your feedback",
        "icon": "star",
        "iconColor": AppTheme.successLight,
        "type": "navigation",
        "route": "/user-profile",
      },
      {
        "title": "Logout",
        "subtitle": "Sign out of your account",
        "icon": "logout",
        "iconColor": AppTheme.errorLight,
        "type": "navigation",
        "action": "logout",
      },
      {
        "title": "Delete Account",
        "subtitle": "Permanently delete your account",
        "icon": "delete_forever",
        "iconColor": AppTheme.errorLight,
        "type": "navigation",
        "action": "deleteAccount",
      },
    ];

    return SettingsSectionWidget(
      title: "Account Settings",
      items: accountItems,
      onSettingChanged: _handleSettingChange,
    );
  }

  void _handleSettingChange(String key, dynamic value) {
    setState(() {
      // Handle setting changes here
      switch (key) {
        case "pushNotifications":
          // Update push notification settings
          break;
        case "workoutReminders":
          // Update workout reminder settings
          break;
        case "meditationReminders":
          // Update meditation reminder settings
          break;
        case "waterReminders":
          // Update water reminder settings
          break;
        case "dataSharing":
          // Update data sharing preferences
          break;
        case "logout":
          _handleLogout();
          return;
        case "deleteAccount":
          _showDeleteAccountDialog();
          return;
        default:
          break;
      }
    });

    // Show feedback to user
    if (key != "logout" && key != "deleteAccount") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Setting updated successfully"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement account deletion logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account deletion is not yet implemented"),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorLight,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
