import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/achievement_badge.dart';
import './widgets/active_challenge_card.dart';
import './widgets/challenge_category_card.dart';
import './widgets/stats_header.dart';
import './widgets/team_challenge_card.dart';

class ChallengesHub extends StatefulWidget {
  const ChallengesHub({super.key});

  @override
  State<ChallengesHub> createState() => _ChallengesHubState();
}

class _ChallengesHubState extends State<ChallengesHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  // Mock data for challenges
  final List<Map<String, dynamic>> challengeCategories = [
    {
      "id": 1,
      "title": "7-Day Kickstart",
      "description":
          "Quick wins to build momentum and establish healthy habits",
      "difficulty": "Beginner",
      "duration": "7 days",
      "participantCount": 15,
      "imageUrl":
          "https://images.pexels.com/photos/3768916/pexels-photo-3768916.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "categoryColor": const Color(0xFF4CAF50),
    },
    {
      "id": 2,
      "title": "30-Day Transform",
      "description":
          "Comprehensive wellness transformation with lasting results",
      "difficulty": "Intermediate",
      "duration": "30 days",
      "participantCount": 8,
      "imageUrl":
          "https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "categoryColor": const Color(0xFF2196F3),
    },
    {
      "id": 3,
      "title": "Team Challenges",
      "description": "Collaborate with friends and compete with other teams",
      "difficulty": "All Levels",
      "duration": "14 days",
      "participantCount": 25,
      "imageUrl":
          "https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "categoryColor": const Color(0xFFFF9800),
    },
    {
      "id": 4,
      "title": "Partner Goals",
      "description": "Achieve wellness goals together with your workout buddy",
      "difficulty": "All Levels",
      "duration": "21 days",
      "participantCount": 12,
      "imageUrl":
          "https://images.pexels.com/photos/3768916/pexels-photo-3768916.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "categoryColor": const Color(0xFF9C27B0),
    },
  ];

  final List<Map<String, dynamic>> activeChallenges = [
    {
      "id": 1,
      "title": "Morning Meditation Master",
      "description": "Start each day with 10 minutes of mindful meditation",
      "progress": 0.65,
      "currentStreak": 5,
      "totalDays": 7,
      "imageUrl":
          "https://images.pexels.com/photos/3822622/pexels-photo-3822622.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "dailyTasks": [
        {"title": "10-minute morning meditation", "completed": true},
        {"title": "Log mood after session", "completed": true},
        {"title": "Practice gratitude journaling", "completed": false},
        {"title": "Share progress with community", "completed": false},
        {"title": "Complete breathing exercise", "completed": false},
      ],
    },
    {
      "id": 2,
      "title": "Hydration Hero",
      "description": "Drink 8 glasses of water daily for optimal hydration",
      "progress": 0.43,
      "currentStreak": 3,
      "totalDays": 7,
      "imageUrl":
          "https://images.pexels.com/photos/416528/pexels-photo-416528.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "dailyTasks": [
        {"title": "Drink water upon waking", "completed": true},
        {"title": "Log 8 glasses throughout day", "completed": false},
        {"title": "Add lemon to afternoon water", "completed": false},
      ],
    },
  ];

  final List<Map<String, dynamic>> teamChallenges = [
    {
      "id": 1,
      "title": "Fitness Warriors Challenge",
      "teamName": "The Wellness Squad",
      "teamProgress": 0.78,
      "rank": 2,
      "totalTeams": 15,
      "imageUrl":
          "https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "teamMembers": [
        {
          "name": "Sarah Johnson",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "name": "Mike Chen",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "name": "Emma Davis",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "name": "Alex Rodriguez",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
        {
          "name": "Lisa Thompson",
          "avatar":
              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> achievements = [
    {
      "title": "First Steps",
      "description": "Complete your first challenge",
      "iconName": "directions_walk",
      "badgeColor": Color(0xFF4CAF50),
      "isUnlocked": true,
      "unlockedDate": DateTime.now().subtract(Duration(days: 5)),
    },
    {
      "title": "Streak Master",
      "description": "Maintain a 7-day streak",
      "iconName": "local_fire_department",
      "badgeColor": Color(0xFFFF5722),
      "isUnlocked": true,
      "unlockedDate": DateTime.now().subtract(Duration(days: 2)),
    },
    {
      "title": "Team Player",
      "description": "Join your first team challenge",
      "iconName": "groups",
      "badgeColor": Color(0xFF2196F3),
      "isUnlocked": true,
      "unlockedDate": DateTime.now().subtract(Duration(days: 10)),
    },
    {
      "title": "Meditation Guru",
      "description": "Complete 30 meditation sessions",
      "iconName": "self_improvement",
      "badgeColor": Color(0xFF9C27B0),
      "isUnlocked": false,
      "unlockedDate": null,
    },
    {
      "title": "Hydration Hero",
      "description": "Log water intake for 14 days",
      "iconName": "water_drop",
      "badgeColor": Color(0xFF00BCD4),
      "isUnlocked": false,
      "unlockedDate": null,
    },
    {
      "title": "Challenge Champion",
      "description": "Complete 10 challenges",
      "iconName": "emoji_events",
      "badgeColor": Color(0xFFFFD700),
      "isUnlocked": false,
      "unlockedDate": null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshChallenges() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _showChallengeCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChallengeCreationModal(),
    );
  }

  Widget _buildChallengeCreationModal() {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Text(
                  'Create Challenge',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Challenge Title',
                      hintText: 'Enter your challenge name',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your challenge goals',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                    ),
                    items: ['7 days', '14 days', '21 days', '30 days']
                        .map((duration) => DropdownMenuItem(
                              value: duration,
                              child: Text(duration),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Handle challenge creation
                      },
                      child: const Text('Create Challenge'),
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Challenges Hub',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/user-profile');
            },
            icon: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'Active'),
            Tab(text: 'Teams'),
            Tab(text: 'Badges'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChallenges,
        child: Column(
          children: [
            // Stats Header
            StatsHeader(
              activeChallenges: activeChallenges.length,
              totalPoints: 2847,
              completedChallenges: 12,
              currentStreak: 5,
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExploreTab(),
                  _buildActiveTab(),
                  _buildTeamsTab(),
                  _buildBadgesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showChallengeCreationModal,
        icon: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildExploreTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Challenges
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Text(
              'Featured Challenges',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 35.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 4.w),
              itemCount: challengeCategories.length,
              itemBuilder: (context, index) {
                final challenge = challengeCategories[index];
                return ChallengeCategoryCard(
                  title: challenge['title'] as String,
                  description: challenge['description'] as String,
                  difficulty: challenge['difficulty'] as String,
                  duration: challenge['duration'] as String,
                  participantCount: challenge['participantCount'] as int,
                  imageUrl: challenge['imageUrl'] as String,
                  categoryColor: challenge['categoryColor'] as Color,
                  onTap: () {
                    // Navigate to challenge details
                  },
                );
              },
            ),
          ),
          SizedBox(height: 3.h),
          // Quick Start Challenges
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Quick Start',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          ...challengeCategories
              .take(2)
              .map((challenge) => Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 15.w,
                          height: 15.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: (challenge['categoryColor'] as Color)
                                .withValues(alpha: 0.1),
                          ),
                          child: CustomIconWidget(
                            iconName: 'emoji_events',
                            color: challenge['categoryColor'] as Color,
                            size: 6.w.clamp(20.0, 28.0),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge['title'] as String,
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                '${challenge['duration']} • ${challenge['participantCount']}k participants',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomIconWidget(
                          iconName: 'arrow_forward_ios',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                      ],
                    ),
                  ))
              ,
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    if (activeChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'emoji_events',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20.w.clamp(60.0, 80.0),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Active Challenges',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Join a challenge to start your wellness journey',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Explore Challenges'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: activeChallenges.length,
      itemBuilder: (context, index) {
        final challenge = activeChallenges[index];
        return ActiveChallengeCard(
          title: challenge['title'] as String,
          description: challenge['description'] as String,
          progress: challenge['progress'] as double,
          currentStreak: challenge['currentStreak'] as int,
          totalDays: challenge['totalDays'] as int,
          dailyTasks:
              (challenge['dailyTasks'] as List).cast<Map<String, dynamic>>(),
          imageUrl: challenge['imageUrl'] as String,
          onTap: () {
            // Navigate to challenge details
          },
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          // Create Team Button
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Handle team creation
                    },
                    icon: CustomIconWidget(
                      iconName: 'group_add',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text('Create Team'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Handle join team
                    },
                    icon: CustomIconWidget(
                      iconName: 'qr_code_scanner',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 20,
                    ),
                    label: const Text('Join Team'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          // Team Challenges
          if (teamChallenges.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Your Teams',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            ...teamChallenges
                .map((team) => TeamChallengeCard(
                      title: team['title'] as String,
                      teamName: team['teamName'] as String,
                      teamMembers: (team['teamMembers'] as List)
                          .cast<Map<String, dynamic>>(),
                      teamProgress: team['teamProgress'] as double,
                      rank: team['rank'] as int,
                      totalTeams: team['totalTeams'] as int,
                      imageUrl: team['imageUrl'] as String,
                      onTap: () {
                        // Navigate to team details
                      },
                    ))
                ,
          ] else ...[
            Center(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  CustomIconWidget(
                    iconName: 'groups',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20.w.clamp(60.0, 80.0),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No Team Challenges',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Create or join a team to compete together',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Achievement Gallery',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Unlock badges by completing challenges and reaching milestones',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Achievement Grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Wrap(
              children: achievements
                  .map((achievement) => AchievementBadge(
                        title: achievement['title'] as String,
                        description: achievement['description'] as String,
                        iconName: achievement['iconName'] as String,
                        badgeColor: achievement['badgeColor'] as Color,
                        isUnlocked: achievement['isUnlocked'] as bool,
                        unlockedDate: achievement['unlockedDate'] as DateTime?,
                        onTap: () {
                          // Show achievement details
                        },
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
