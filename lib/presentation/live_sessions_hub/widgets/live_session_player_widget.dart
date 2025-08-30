import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import './session_chat_widget.dart';
import './session_poll_widget.dart';
import './session_reactions_widget.dart';

class LiveSessionPlayer extends StatefulWidget {
  final Map<String, dynamic> session;
  final VoidCallback onLeave;

  const LiveSessionPlayer({
    super.key,
    required this.session,
    required this.onLeave,
  });

  @override
  State<LiveSessionPlayer> createState() => _LiveSessionPlayerState();
}

class _LiveSessionPlayerState extends State<LiveSessionPlayer>
    with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;

  late AnimationController _pulseController;
  late AnimationController _reactionController;

  bool _isFullscreen = false;
  bool _showControls = true;
  bool _showChat = false;
  bool _showParticipants = false;
  bool _heartRateSharing = false;
  bool _isAudioOnly = false;

  List<Map<String, dynamic>> _chatMessages = [];
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _activePolls = [];

  int _participantCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupWakelock();
    _loadSessionData();
    _setupRealtimeSubscriptions();
    _requestNotificationPermission();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _reactionController.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _reactionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _setupWakelock() {
    WakelockPlus.enable();
  }

  void _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _loadSessionData() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      // Load participants
      final participantsResponse = await _supabaseService.client
          .from('session_participants')
          .select('''
            *,
            user_profiles!inner(id, full_name, avatar_url)
          ''')
          .eq('session_id', widget.session['session_id'])
          .eq('status', 'joined');

      // Load chat messages
      final chatResponse = await _supabaseService.client
          .from('session_chat')
          .select('''
            *,
            user_profiles!inner(id, full_name, avatar_url)
          ''')
          .eq('session_id', widget.session['session_id'])
          .order('created_at', ascending: true)
          .limit(50);

      // Load active polls
      final pollsResponse = await _supabaseService.client
          .from('session_polls')
          .select('*')
          .eq('session_id', widget.session['session_id'])
          .eq('is_active', true);

      if (mounted) {
        setState(() {
          _participants = List<Map<String, dynamic>>.from(participantsResponse);
          _chatMessages = List<Map<String, dynamic>>.from(chatResponse);
          _activePolls = List<Map<String, dynamic>>.from(pollsResponse);
          _participantCount = _participants.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load session data: ${e.toString()}';
        });
      }
    }
  }

  void _setupRealtimeSubscriptions() {
    final sessionId = widget.session['session_id'];

    // Listen for chat messages
    _supabaseService.client
        .channel('session_chat_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'session_chat',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) => _handleNewChatMessage(payload.newRecord),
        )
        .subscribe();

    // Listen for participant changes
    _supabaseService.client
        .channel('session_participants_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'session_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (_) => _loadSessionData(),
        )
        .subscribe();

    // Listen for reactions
    _supabaseService.client
        .channel('session_reactions_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'session_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) => _handleNewReaction(payload.newRecord),
        )
        .subscribe();
  }

  void _handleNewChatMessage(Map<String, dynamic> message) {
    setState(() {
      _chatMessages.add(message);
      if (_chatMessages.length > 50) {
        _chatMessages.removeAt(0);
      }
    });
  }

  void _handleNewReaction(Map<String, dynamic> reaction) {
    _reactionController.forward().then((_) {
      _reactionController.reset();
    });
  }

  Future<void> _sendChatMessage(String message) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.client.from('session_chat').insert({
        'session_id': widget.session['session_id'],
        'user_id': currentUser.id,
        'message': message,
        'message_type': 'text',
      });
    } catch (e) {
      _showSnackBar('Failed to send message');
    }
  }

  Future<void> _sendReaction(String reactionType) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.client.from('session_reactions').insert({
        'session_id': widget.session['session_id'],
        'user_id': currentUser.id,
        'reaction_type': reactionType,
      });
    } catch (e) {
      _showSnackBar('Failed to send reaction');
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _leaveSession() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.client
          .from('session_participants')
          .update(
              {'status': 'left', 'left_at': DateTime.now().toIso8601String()})
          .eq('session_id', widget.session['session_id'])
          .eq('user_id', currentUser.id);

      widget.onLeave();
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('Failed to leave session');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Main video/content area
              Positioned.fill(
                child: _buildMainContent(),
              ),

              // Top controls
              if (_showControls && !_isFullscreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopControls(),
                ),

              // Bottom controls
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomControls(),
                ),

              // Side panels
              if (_showChat)
                Positioned(
                  right: 0,
                  top: _showControls && !_isFullscreen ? 15.h : 0,
                  bottom: _showControls ? 15.h : 0,
                  child: SessionChatWidget(
                    messages: _chatMessages,
                    onSendMessage: _sendChatMessage,
                    onClose: () => setState(() => _showChat = false),
                  ),
                ),

              if (_showParticipants)
                Positioned(
                  right: 0,
                  top: _showControls && !_isFullscreen ? 15.h : 0,
                  bottom: _showControls ? 15.h : 0,
                  child: _buildParticipantsPanel(),
                ),

              // Reactions overlay
              Positioned.fill(
                child: SessionReactionsWidget(
                  controller: _reactionController,
                ),
              ),

              // Active polls
              if (_activePolls.isNotEmpty)
                Positioned(
                  top: 20.h,
                  left: 4.w,
                  right: _showChat || _showParticipants ? 35.w : 4.w,
                  child: SessionPollWidget(
                    poll: _activePolls.first,
                    onVote: (optionIndex) =>
                        _votePoll(_activePolls.first['id'], optionIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image: _isAudioOnly
            ? null
            : DecorationImage(
                image: NetworkImage(widget.session['session_image_url'] ??
                    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=800&q=80'),
                fit: BoxFit.cover,
              ),
      ),
      child: _isAudioOnly ? _buildAudioOnlyInterface() : null,
    );
  }

  Widget _buildAudioOnlyInterface() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBlue.withAlpha(77),
            Colors.black.withAlpha(204),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Live pulse animation
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(0.3 + 0.7 * _pulseController.value),
                      width: 3,
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(widget
                                .session['instructor_avatar'] ??
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 4.h),

            Text(
              widget.session['title'] ?? 'Live Session',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            Text(
              'Audio Only Mode',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      height: 15.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(204),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Top row
            Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: _leaveSession,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ),

                SizedBox(width: 4.w),

                // Session info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 2.w,
                            height: 2.w,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.session['title'] ?? 'Live Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Participant count
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _participantCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      height: 15.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(204),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Reaction buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildReactionButton('❤️', 'heart'),
                SizedBox(width: 6.w),
                _buildReactionButton('🔥', 'fire'),
                SizedBox(width: 6.w),
                _buildReactionButton('👏', 'clap'),
                SizedBox(width: 6.w),
                _buildReactionButton('💪', 'muscle'),
              ],
            ),

            SizedBox(height: 2.h),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isAudioOnly ? Icons.videocam_off : Icons.videocam,
                  label: _isAudioOnly ? 'Video' : 'Audio',
                  onTap: () => setState(() => _isAudioOnly = !_isAudioOnly),
                ),
                _buildControlButton(
                  icon: Icons.chat_bubble,
                  label: 'Chat',
                  isActive: _showChat,
                  onTap: () => setState(() {
                    _showChat = !_showChat;
                    _showParticipants = false;
                  }),
                ),
                _buildControlButton(
                  icon: Icons.people,
                  label: 'People',
                  isActive: _showParticipants,
                  onTap: () => setState(() {
                    _showParticipants = !_showParticipants;
                    _showChat = false;
                  }),
                ),
                _buildControlButton(
                  icon:
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  label: _isFullscreen ? 'Exit' : 'Full',
                  onTap: _toggleFullscreen,
                ),
                _buildControlButton(
                  icon: Icons.exit_to_app,
                  label: 'Leave',
                  isDestructive: true,
                  onTap: _leaveSession,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(String emoji, String type) {
    return GestureDetector(
      onTap: () => _sendReaction(type),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue
                  : Colors.black.withAlpha(128),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 6.w,
            ),
          ),
          SizedBox(height: 1.w),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.white,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsPanel() {
    return Container(
      width: 35.w,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(204),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4.w),
          bottomLeft: Radius.circular(4.w),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Participants',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showParticipants = false),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 5.w,
                  ),
                ),
              ],
            ),
          ),

          // Participants list
          Expanded(
            child: ListView.builder(
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                final userProfile = participant['user_profiles'];

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.w,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(77),
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child: CustomImageWidget(
                            imageUrl: userProfile['avatar_url'] ??
                                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          userProfile['full_name'] ?? 'Participant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _votePoll(String pollId, int optionIndex) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.client.from('session_poll_votes').insert({
        'poll_id': pollId,
        'user_id': currentUser.id,
        'option_index': optionIndex,
      });
    } catch (e) {
      _showSnackBar('Failed to vote');
    }
  }
}