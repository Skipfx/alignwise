import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/stats_overview_widget.dart';
import './widgets/subscription_card_widget.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  // Mock user data
  final Map<String, dynamic> userData = {
    "name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "avatar":
        "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
    "wellnessLevel": 7,
    "levelProgress": 0.73,
  };

  // Mock stats data
  final Map<String, dynamic> statsData = {
    "totalWorkouts": 142,
    "meditationMinutes": 2847,
    "challengesCompleted": 23,
    "currentStreak": 31,
    "recentAchievements": [
      {
        "title": "Consistency Champion",
        "description": "Completed 30-day wellness challenge",
        "icon": "military_tech",
        "date": "3 days ago",
        "color": AppTheme.successLight,
      },
      {
        "title": "Mindful Master",
        "description": "Reached 150 hours of meditation",
        "icon": "psychology",
        "date": "1 week ago",
        "color": AppTheme.accentLight,
      },
    ],
  };

  // Mock subscription data
  final Map<String, dynamic> subscriptionData = {
    "isPremium": true,
    "planName": "Annual Premium",
    "nextBilling": "August 6, 2026",
    "amount": "\$79.99/year",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeaderWidget(userData: userData),
            StatsOverviewWidget(statsData: statsData),
            _buildPersonalInformationSection(),
            _buildHealthGoalsSection(),
            _buildAppPreferencesSection(),
            SubscriptionCardWidget(subscriptionData: subscriptionData),
            _buildAccountSettingsSection(),
            SizedBox(height: 10.h), // Bottom padding for navigation
          ],
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
        "subtitle": "28 years old",
        "icon": "cake",
        "iconColor": AppTheme.secondaryLight,
        "type": "selection",
        "selectedValue": "28",
      },
      {
        "title": "Height & Weight",
        "subtitle": "5'6\" • 140 lbs",
        "icon": "straighten",
        "iconColor": AppTheme.accentLight,
        "type": "selection",
        "selectedValue": "5'6\" • 140 lbs",
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
        default:
          break;
      }
    });

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Setting updated successfully"),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
