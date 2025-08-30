import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../services/wellness_service.dart';
import './widgets/activity_feed_card.dart';
import './widgets/challenge_discovery_card.dart';
import './widgets/create_post_modal.dart';
import './widgets/friend_activity_header.dart';
import './widgets/story_highlights_widget.dart';

class CommunityFeed extends StatefulWidget {
  const CommunityFeed({super.key});

  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final WellnessService _wellnessService = WellnessService();
  
  List<Map<String, dynamic>> _feedActivities = [];
  List<Map<String, dynamic>> _activeStories = [];
  List<Map<String, dynamic>> _friendSuggestions = [];
  List<Map<String, dynamic>> _trendingChallenges = [];
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreActivities();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadFeedActivities(refresh: true),
        _loadActiveStories(),
        _loadTrendingChallenges(),
        _loadFriendSuggestions(),
      ]);
    } catch (error) {
      print('Error loading initial data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load community feed'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFeedActivities({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMoreData = true;
    }

    try {
      final supabase = SupabaseService.instance.client;
      
      // Get community feed using the database function
      final response = await supabase.rpc('get_community_feed', params: {
        'requesting_user_id': SupabaseService.instance.currentUser?.id,
        'feed_limit': _pageSize,
        'offset_count': _currentPage * _pageSize,
      });

      final List<Map<String, dynamic>> newActivities = 
          List<Map<String, dynamic>>.from(response ?? []);

      setState(() {
        if (refresh) {
          _feedActivities = newActivities;
        } else {
          _feedActivities.addAll(newActivities);
        }
        _hasMoreData = newActivities.length == _pageSize;
        _currentPage++;
      });
    } catch (error) {
      print('Error loading feed activities: $error');
      // Fallback to mock data in preview mode
      if (refresh) {
        _feedActivities = _getMockFeedData();
        _hasMoreData = false;
      }
    }
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() => _isLoadingMore = true);
    await _loadFeedActivities();
    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadActiveStories() async {
    try {
      final supabase = SupabaseService.instance.client;
      
      final response = await supabase
          .from('user_stories')
          .select('''
            id, user_id, title, media_url, story_type, description, 
            view_count, created_at,
            user_profiles!inner(full_name, avatar_url)
          ''')
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _activeStories = List<Map<String, dynamic>>.from((response as List?) ?? []);
      });
    } catch (error) {
      print('Error loading stories: $error');
      // Fallback to mock data
      _activeStories = _getMockStoriesData();
    }
  }

  Future<void> _loadTrendingChallenges() async {
    try {
      final supabase = SupabaseService.instance.client;
      
      final response = await supabase
          .from('community_challenges')
          .select('''
            id, title, description, challenge_type, target_value, target_unit,
            start_date, end_date, status, cover_image_url, badge_icon,
            user_profiles!inner(full_name, avatar_url)
          ''')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _trendingChallenges = List<Map<String, dynamic>>.from((response as List?) ?? []);
      });
    } catch (error) {
      print('Error loading challenges: $error');
      // Fallback to mock data
      _trendingChallenges = _getMockChallengesData();
    }
  }

  Future<void> _loadFriendSuggestions() async {
    try {
      final supabase = SupabaseService.instance.client;
      
      final response = await supabase.rpc('get_friend_suggestions', params: {
        'requesting_user_id': SupabaseService.instance.currentUser?.id,
        'suggestion_limit': 5,
      });

      setState(() {
        _friendSuggestions = List<Map<String, dynamic>>.from(response ?? []);
      });
    } catch (error) {
      print('Error loading friend suggestions: $error');
      // Fallback to mock data
      _friendSuggestions = _getMockFriendSuggestions();
    }
  }

  Future<void> _refreshFeed() async {
    await _loadInitialData();
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModal(
        onPostCreated: () {
          Navigator.pop(context);
          _refreshFeed();
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refreshFeed,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Tab selector
                  SliverToBoxAdapter(child: _buildTabSelector()),
                  
                  // Tab content
                  if (_selectedTab == 0) ..._buildForYouTab(),
                  if (_selectedTab == 1) ..._buildFollowingTab(),
                  if (_selectedTab == 2) ..._buildDiscoverTab(),
                  
                  // Load more indicator
                  if (_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Center(child: CircularProgressIndicator()))),
                ])),
      floatingActionButton: _buildFloatingActionButton());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
          if (SupabaseService.instance.isSignedIn)
            Text(
              '${_friendSuggestions.length} friend suggestions',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.white.withAlpha(204))),
        ]),
      actions: [
        IconButton(
          onPressed: () {
            // Navigate to friend requests
          },
          icon: Stack(
            children: [
              Icon(Icons.people_outline, color: Colors.white, size: 24.sp),
              if (_friendSuggestions.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6)),
                    constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text(
                      '${_friendSuggestions.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center))),
            ])),
        IconButton(
          onPressed: () {
            // Navigate to notifications
          },
          icon: Icon(Icons.notifications_outlined, color: Colors.white)),
        SizedBox(width: 2.w),
      ]);
  }

  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: Offset(0, 2)),
        ]),
      child: Row(
        children: [
          _buildTabItem('For You', 0),
          _buildTabItem('Following', 1),
          _buildTabItem('Discover', 2),
        ]));
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            
            borderRadius: BorderRadius.circular(25)),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.blue : Colors.grey
            )))));
  }

  List<Widget> _buildForYouTab() {
    return [
      // Story highlights
      if (_activeStories.isNotEmpty)
        SliverToBoxAdapter(
          child: StoryHighlightsWidget(
            stories: _activeStories,
            onStoryTap: _viewStory)),

      // Friend activity header
      SliverToBoxAdapter(
        child: FriendActivityHeader(
          friendCount: _friendSuggestions.length,
          onViewAllFriends: () {
            // Navigate to friends list
          })),

      // Activity feed
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final activity = _feedActivities[index];
            return ActivityFeedCard(
              activity: activity,
              onReaction: (reactionType) => _handleReaction(activity['activity_id'], reactionType),
              onComment: () => _showComments(activity['activity_id']),
              onShare: () => _shareActivity(activity['activity_id']));
          },
          childCount: _feedActivities.length)),
    ];
  }

  List<Widget> _buildFollowingTab() {
    final followingActivities = _feedActivities
        .where((activity) => activity['user_has_reacted'] != null)
        .toList();

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final activity = followingActivities[index];
            return ActivityFeedCard(
              activity: activity,
              onReaction: (reactionType) => _handleReaction(activity['activity_id'], reactionType),
              onComment: () => _showComments(activity['activity_id']),
              onShare: () => _shareActivity(activity['activity_id']));
          },
          childCount: followingActivities.length)),
    ];
  }

  List<Widget> _buildDiscoverTab() {
    return [
      // Trending challenges section
      if (_trendingChallenges.isNotEmpty)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'Trending Challenges',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold))),
              SizedBox(
                height: 25.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  itemCount: _trendingChallenges.length,
                  itemBuilder: (context, index) {
                    return ChallengeDiscoveryCard(
                      challenge: _trendingChallenges[index],
                      onJoin: () => _joinChallenge(_trendingChallenges[index]['id']));
                  })),
            ])),

      // Friend suggestions
      if (_friendSuggestions.isNotEmpty)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'People You May Know',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold))),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _friendSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _friendSuggestions[index];
                  return _buildFriendSuggestionCard(suggestion);
                }),
            ])),

      // Discovery activities
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final activity = _feedActivities[index];
            return ActivityFeedCard(
              activity: activity,
              onReaction: (reactionType) => _handleReaction(activity['activity_id'], reactionType),
              onComment: () => _showComments(activity['activity_id']),
              onShare: () => _shareActivity(activity['activity_id']));
          },
          childCount: _feedActivities.length)),
    ];
  }

  Widget _buildFriendSuggestionCard(Map<String, dynamic> suggestion) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: Offset(0, 2)),
        ]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 6.w,
            
            backgroundImage: suggestion['avatar_url'] != null
                ? CachedNetworkImageProvider(suggestion['avatar_url'])
                : null,
            child: suggestion['avatar_url'] == null
                ? Text(
                    suggestion['full_name']?.substring(0, 1).toUpperCase() ?? '?',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold))
                : null),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion['full_name'] ?? 'Unknown User',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600)),
                if (suggestion['mutual_friends_count'] > 0)
                  Text(
                    '${suggestion['mutual_friends_count']} mutual friends',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp)),
              ])),
          ElevatedButton(
            onPressed: () => _sendFriendRequest(suggestion['user_id']),
            style: ElevatedButton.styleFrom(
              
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
            child: Text(
              'Add Friend',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600))),
        ]));
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCreatePostModal,
      
      child: Icon(Icons.add, color: Colors.white));
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 2.h),
          Text(
            'Loading community feed...',
            style: GoogleFonts.inter(
              fontSize: 14.sp)),
        ]));
  }

  Future<void> _handleReaction(String activityId, String reactionType) async {
    try {
      final supabase = SupabaseService.instance.client;
      
      // Toggle reaction
      await supabase.from('activity_reactions').upsert({
        'activity_id': activityId,
        'user_id': SupabaseService.instance.currentUser?.id,
        'reaction_type': reactionType,
      }, onConflict: 'activity_id,user_id,reaction_type');

      // Refresh the specific activity in the feed
      _refreshFeed();
    } catch (error) {
      print('Error handling reaction: $error');
    }
  }

  void _showComments(String activityId) {
    // Show comments bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
              child: Text(
                'Comments',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold))),
            Expanded(
              child: Center(
                child: Text(
                  'Comments functionality coming soon!',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp)))),
          ])));
  }

  void _shareActivity(String activityId) {
    // Implement activity sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing functionality coming soon!')));
  }

  void _viewStory(Map<String, dynamic> story) {
    // Implement story viewing
    print('Viewing story: ${story['title']}');
  }

  Future<void> _joinChallenge(String challengeId) async {
    try {
      final supabase = SupabaseService.instance.client;
      
      await supabase.from('challenge_participants').insert({
        'challenge_id': challengeId,
        'user_id': SupabaseService.instance.currentUser?.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined challenge!'),
          backgroundColor: Colors.green));
    } catch (error) {
      print('Error joining challenge: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join challenge'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      final supabase = SupabaseService.instance.client;
      
      await supabase.from('user_friends').insert({
        'requester_id': SupabaseService.instance.currentUser?.id,
        'requested_id': userId,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: Colors.green));

      // Remove from suggestions
      setState(() {
        _friendSuggestions.removeWhere((s) => s['user_id'] == userId);
      });
    } catch (error) {
      print('Error sending friend request: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request'),
          backgroundColor: Colors.red));
    }
  }

  // Mock data for preview mode
  List<Map<String, dynamic>> _getMockFeedData() {
    return [
      {
        'activity_id': '1',
        'user_id': '1',
        'user_name': 'Sarah Johnson',
        'user_avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b526?w=150',
        'activity_type': 'workout_completed',
        'title': 'Completed Morning Run! 🏃‍♀️',
        'description': 'Just finished a amazing 5km run in the park. Weather was perfect and feeling energized for the day!',
        'activity_data': {'duration_minutes': 30, 'distance_km': 5.0, 'calories_burned': 285},
        'media_urls': ['https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'],
        'tags': ['running', 'cardio', 'morning'],
        'is_achievement': true,
        'achievement_badge': 'early_bird',
        'created_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'reaction_count': 12,
        'comment_count': 3,
        'user_has_reacted': false,
      },
      {
        'activity_id': '2',
        'user_id': '2',
        'user_name': 'Mike Chen',
        'user_avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'activity_type': 'meditation_session',
        'title': 'Peaceful Morning Meditation 🧘‍♂️',
        'description': 'Started the day with 20 minutes of mindfulness meditation. Feeling centered and ready to tackle the day!',
        'activity_data': {'duration_minutes': 20, 'mood_before': 'neutral', 'mood_after': 'happy'},
        'media_urls': [],
        'tags': ['meditation', 'mindfulness', 'morning'],
        'is_achievement': false,
        'achievement_badge': null,
        'created_at': DateTime.now().subtract(Duration(hours: 4)).toIso8601String(),
        'reaction_count': 8,
        'comment_count': 1,
        'user_has_reacted': true,
      },
      {
        'activity_id': '3',
        'user_id': '3',
        'user_name': 'Emily Davis',
        'user_avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        'activity_type': 'meal_logged',
        'title': 'Healthy Breakfast Bowl 🥗',
        'description': 'Fueling up with this colorful acai bowl packed with fresh fruits and granola!',
        'activity_data': {'calories': 320, 'protein': 12, 'meal_type': 'breakfast'},
        'media_urls': ['https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=400'],
        'tags': ['nutrition', 'healthy', 'breakfast'],
        'is_achievement': false,
        'achievement_badge': null,
        'created_at': DateTime.now().subtract(Duration(hours: 6)).toIso8601String(),
        'reaction_count': 15,
        'comment_count': 5,
        'user_has_reacted': false,
      },
    ];
  }

  List<Map<String, dynamic>> _getMockStoriesData() {
    return [
      {
        'id': '1',
        'user_id': '1',
        'title': 'Workout Selfie',
        'media_url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200',
        'story_type': 'workout_selfie',
        'user_profiles': {
          'full_name': 'Sarah Johnson',
          'avatar_url': 'https://images.unsplash.com/photo-1494790108755-2616b612b526?w=100',
        },
      },
      {
        'id': '2',
        'user_id': '2',
        'title': 'Morning Motivation',
        'media_url': 'https://images.unsplash.com/photo-1506629905607-c7b5fa2c6cc8?w=200',
        'story_type': 'motivation',
        'user_profiles': {
          'full_name': 'Mike Chen',
          'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        },
      },
    ];
  }

  List<Map<String, dynamic>> _getMockChallengesData() {
    return [
      {
        'id': '1',
        'title': '30-Day Fitness Challenge',
        'description': 'Complete at least 20 minutes of exercise every day for 30 days',
        'challenge_type': 'fitness',
        'target_value': 30,
        'target_unit': 'days',
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        'cover_image_url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300',
        'badge_icon': 'fitness_champion',
      },
      {
        'id': '2',
        'title': 'Mindful May',
        'description': 'Practice meditation for at least 10 minutes every day in May',
        'challenge_type': 'mindfulness',
        'target_value': 31,
        'target_unit': 'days',
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(Duration(days: 31)).toIso8601String(),
        'cover_image_url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300',
        'badge_icon': 'zen_master',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockFriendSuggestions() {
    return [
      {
        'user_id': '4',
        'full_name': 'Alex Rivera',
        'avatar_url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        'mutual_friends_count': 3,
      },
      {
        'user_id': '5',
        'full_name': 'Jessica Wong',
        'avatar_url': 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150',
        'mutual_friends_count': 1,
      },
    ];
  }
}