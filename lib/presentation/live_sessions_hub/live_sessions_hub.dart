import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_error_widget.dart';
import '../dashboard_home/widgets/bottom_tab_navigation.dart';
import './widgets/featured_sessions_widget.dart';
import './widgets/live_session_player_widget.dart';
import './widgets/live_sessions_header_widget.dart';
import './widgets/session_categories_widget.dart';
import './widgets/session_hero_widget.dart';
import './widgets/upcoming_sessions_widget.dart';

class LiveSessionsHub extends StatefulWidget {
  const LiveSessionsHub({super.key});

  @override
  State<LiveSessionsHub> createState() => _LiveSessionsHubState();
}

class _LiveSessionsHubState extends State<LiveSessionsHub>
    with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late TabController _categoryController;

  List<Map<String, dynamic>> _liveSessions = [];
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _featuredSessions = [];

  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';
  Map<String, dynamic>? _currentLiveSession;

  final List<String> _categories = [
    'all',
    'yoga',
    'hiit',
    'meditation',
    'nutrition',
    'pilates',
    'strength',
  ];

  @override
  void initState() {
    super.initState();
    _categoryController = TabController(
      length: _categories.length,
      vsync: this,
    );
    _loadSessionsData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = _supabaseService.currentUser;

      // Get live sessions feed
      final sessionsResponse = await _supabaseService.client.rpc(
        'get_live_sessions_feed',
        params: {'user_uuid': currentUser?.id},
      );

      if (sessionsResponse is List) {
        final allSessions = List<Map<String, dynamic>>.from(sessionsResponse);

        setState(() {
          _liveSessions =
              allSessions
                  .where((session) => session['status'] == 'live')
                  .toList();

          _upcomingSessions =
              allSessions
                  .where((session) => session['status'] == 'scheduled')
                  .toList();

          _featuredSessions = allSessions.take(3).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load live sessions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _setupRealtimeSubscription() {
    // Listen for session status changes
    _supabaseService.client
        .channel('live_sessions_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_sessions',
          callback: (_) => _loadSessionsData(),
        )
        .subscribe();

    // Listen for participant count changes
    _supabaseService.client
        .channel('session_participants_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'session_participants',
          callback: (_) => _loadSessionsData(),
        )
        .subscribe();
  }

  List<Map<String, dynamic>> _getFilteredSessions(
    List<Map<String, dynamic>> sessions,
  ) {
    if (_selectedCategory == 'all') return sessions;
    return sessions
        .where((session) => session['session_type'] == _selectedCategory)
        .toList();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Future<void> _joinLiveSession(Map<String, dynamic> session) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      final success = await _supabaseService.client.rpc(
        'join_live_session',
        params: {
          'session_uuid': session['session_id'],
          'user_uuid': currentUser.id,
        },
      );

      if (success == true) {
        setState(() {
          _currentLiveSession = session;
        });

        // Show live session player
        _showLiveSessionPlayer(session);
      } else {
        _showSnackBar('Unable to join session. It may be full.');
      }
    } catch (e) {
      _showSnackBar('Failed to join session: ${e.toString()}');
    }
  }

  void _showLiveSessionPlayer(Map<String, dynamic> session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => LiveSessionPlayer(
              session: session,
              onLeave: () {
                setState(() {
                  _currentLiveSession = null;
                });
                _loadSessionsData();
              },
            ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _bookmarkSession(String sessionId, bool isBookmarked) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      if (isBookmarked) {
        await _supabaseService.client
            .from('session_bookmarks')
            .delete()
            .eq('session_id', sessionId)
            .eq('user_id', currentUser.id);
      } else {
        await _supabaseService.client.from('session_bookmarks').insert({
          'session_id': sessionId,
          'user_id': currentUser.id,
        });
      }

      _loadSessionsData();
    } catch (e) {
      _showSnackBar('Failed to bookmark session');
    }
  }

  Future<void> _followInstructor(String instructorId, bool isFollowing) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      if (isFollowing) {
        await _supabaseService.client
            .from('instructor_followers')
            .delete()
            .eq('instructor_id', instructorId)
            .eq('follower_id', currentUser.id);
      } else {
        await _supabaseService.client.from('instructor_followers').insert({
          'instructor_id': instructorId,
          'follower_id': currentUser.id,
        });
      }

      _loadSessionsData();
    } catch (e) {
      _showSnackBar('Failed to follow instructor');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomTabNavigation(
          currentIndex: 3,
          onTap: (index) {},
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: CustomErrorWidget(message: _error!, onRetry: _loadSessionsData),
        bottomNavigationBar: BottomTabNavigation(
          currentIndex: 3,
          onTap: (index) {},
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessionsData,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with live session count
                  LiveSessionsHeaderWidget(
                    liveSessionsCount: _liveSessions.length,
                    upcomingCount: _upcomingSessions.length,
                  ),

                  SizedBox(height: 3.h),

                  // Hero section for featured live session
                  if (_featuredSessions.isNotEmpty) ...[
                    SessionHeroWidget(
                      session: _featuredSessions.first,
                      onJoin: () => _joinLiveSession(_featuredSessions.first),
                      onBookmark:
                          (isBookmarked) => _bookmarkSession(
                            _featuredSessions.first['session_id'],
                            isBookmarked,
                          ),
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // Category tabs
                  SessionCategoriesWidget(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: _onCategoryChanged,
                    controller: _categoryController,
                  ),

                  SizedBox(height: 3.h),

                  // Live sessions section
                  if (_liveSessions.isNotEmpty) ...[
                    Text(
                      'Live Now • ${_getFilteredSessions(_liveSessions).length}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FeaturedSessionsWidget(
                      sessions: _getFilteredSessions(_liveSessions),
                      onJoinSession: _joinLiveSession,
                      onBookmark: _bookmarkSession,
                      onFollowInstructor: _followInstructor,
                      isLive: true,
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // Upcoming sessions section
                  if (_upcomingSessions.isNotEmpty) ...[
                    Text(
                      'Upcoming Sessions',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    UpcomingSessionsWidget(
                      sessions: _getFilteredSessions(_upcomingSessions),
                      onBookmark: _bookmarkSession,
                      onFollowInstructor: _followInstructor,
                    ),
                  ],

                  SizedBox(height: 10.h), // Bottom padding for navigation
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomTabNavigation(
        currentIndex: 3,
        onTap: (index) {},
      ),
    );
  }
}
