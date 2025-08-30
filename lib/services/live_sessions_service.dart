import 'package:supabase_flutter/supabase_flutter.dart';

class LiveSessionsService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get live sessions feed
  Future<List<Map<String, dynamic>>> getLiveSessionsFeed(
      {String? userId}) async {
    try {
      final response = await _client.rpc('get_live_sessions_feed', params: {
        'user_uuid': userId,
      });

      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load live sessions: ${e.toString()}');
    }
  }

  // Join a live session
  Future<bool> joinLiveSession(String sessionId, String userId) async {
    try {
      final result = await _client.rpc('join_live_session', params: {
        'session_uuid': sessionId,
        'user_uuid': userId,
      });

      return result == true;
    } catch (e) {
      throw Exception('Failed to join session: ${e.toString()}');
    }
  }

  // Leave a live session
  Future<void> leaveLiveSession(String sessionId, String userId) async {
    try {
      await _client
          .from('session_participants')
          .update({
            'status': 'left',
            'left_at': DateTime.now().toIso8601String(),
          })
          .eq('session_id', sessionId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to leave session: ${e.toString()}');
    }
  }

  // Get session participants
  Future<List<Map<String, dynamic>>> getSessionParticipants(
      String sessionId) async {
    try {
      final response = await _client
          .from('session_participants')
          .select('''
            *,
            user_profiles!inner(id, full_name, avatar_url)
          ''')
          .eq('session_id', sessionId)
          .eq('status', 'joined')
          .order('joined_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load participants: ${e.toString()}');
    }
  }

  // Get session chat messages
  Future<List<Map<String, dynamic>>> getSessionChat(String sessionId,
      {int limit = 50}) async {
    try {
      final response = await _client
          .from('session_chat')
          .select('''
            *,
            user_profiles!inner(id, full_name, avatar_url)
          ''')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load chat messages: ${e.toString()}');
    }
  }

  // Send chat message
  Future<void> sendChatMessage({
    required String sessionId,
    required String userId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      await _client.from('session_chat').insert({
        'session_id': sessionId,
        'user_id': userId,
        'message': message,
        'message_type': messageType,
      });
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Send reaction
  Future<void> sendReaction({
    required String sessionId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      await _client.from('session_reactions').insert({
        'session_id': sessionId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
    } catch (e) {
      throw Exception('Failed to send reaction: ${e.toString()}');
    }
  }

  // Bookmark/Unbookmark session
  Future<void> toggleSessionBookmark(
      String sessionId, String userId, bool isBookmarked) async {
    try {
      if (isBookmarked) {
        await _client
            .from('session_bookmarks')
            .delete()
            .eq('session_id', sessionId)
            .eq('user_id', userId);
      } else {
        await _client.from('session_bookmarks').insert({
          'session_id': sessionId,
          'user_id': userId,
        });
      }
    } catch (e) {
      throw Exception('Failed to bookmark session: ${e.toString()}');
    }
  }

  // Follow/Unfollow instructor
  Future<void> toggleInstructorFollow(
      String instructorId, String userId, bool isFollowing) async {
    try {
      if (isFollowing) {
        await _client
            .from('instructor_followers')
            .delete()
            .eq('instructor_id', instructorId)
            .eq('follower_id', userId);
      } else {
        await _client.from('instructor_followers').insert({
          'instructor_id': instructorId,
          'follower_id': userId,
        });
      }
    } catch (e) {
      throw Exception('Failed to follow instructor: ${e.toString()}');
    }
  }

  // Get active polls for session
  Future<List<Map<String, dynamic>>> getActivePolls(String sessionId) async {
    try {
      final response = await _client
          .from('session_polls')
          .select('*')
          .eq('session_id', sessionId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load polls: ${e.toString()}');
    }
  }

  // Vote on poll
  Future<void> votePoll({
    required String pollId,
    required String userId,
    required int optionIndex,
  }) async {
    try {
      await _client.from('session_poll_votes').insert({
        'poll_id': pollId,
        'user_id': userId,
        'option_index': optionIndex,
      });
    } catch (e) {
      throw Exception('Failed to vote: ${e.toString()}');
    }
  }

  // Submit Q&A question
  Future<void> submitQuestion({
    required String sessionId,
    required String userId,
    required String question,
  }) async {
    try {
      await _client.from('session_qna').insert({
        'session_id': sessionId,
        'user_id': userId,
        'question': question,
      });
    } catch (e) {
      throw Exception('Failed to submit question: ${e.toString()}');
    }
  }

  // Rate session
  Future<void> rateSession({
    required String sessionId,
    required String userId,
    required int rating,
    String? review,
  }) async {
    try {
      await _client.from('session_ratings').insert({
        'session_id': sessionId,
        'user_id': userId,
        'rating': rating,
        'review': review,
      });
    } catch (e) {
      throw Exception('Failed to rate session: ${e.toString()}');
    }
  }

  // Get user's bookmarked sessions
  Future<List<Map<String, dynamic>>> getUserBookmarks(String userId) async {
    try {
      final response = await _client.from('session_bookmarks').select('''
            *,
            live_sessions!inner(
              *,
              user_profiles!instructor_id(full_name, avatar_url)
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load bookmarks: ${e.toString()}');
    }
  }

  // Get user's followed instructors
  Future<List<Map<String, dynamic>>> getFollowedInstructors(
      String userId) async {
    try {
      final response = await _client.from('instructor_followers').select('''
            *,
            user_profiles!instructor_id(id, full_name, avatar_url, bio)
          ''').eq('follower_id', userId).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load followed instructors: ${e.toString()}');
    }
  }

  // Subscribe to real-time updates
  RealtimeChannel subscribeToSessionUpdates({
    required String sessionId,
    required Function(Map<String, dynamic>) onChatMessage,
    required Function() onParticipantChange,
    required Function(Map<String, dynamic>) onReaction,
  }) {
    final channel = _client.channel('live_session_$sessionId');

    // Chat messages
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'session_chat',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (payload) => onChatMessage(payload.newRecord),
    );

    // Participant changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'session_participants',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (_) => onParticipantChange(),
    );

    // Reactions
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'session_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (payload) => onReaction(payload.newRecord),
    );

    channel.subscribe();
    return channel;
  }

  // Update heart rate sharing preference
  Future<void> updateHeartRateSharing({
    required String sessionId,
    required String userId,
    required bool enabled,
  }) async {
    try {
      await _client
          .from('session_participants')
          .update({'heart_rate_sharing': enabled})
          .eq('session_id', sessionId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update heart rate sharing: ${e.toString()}');
    }
  }

  // Search sessions
  Future<List<Map<String, dynamic>>> searchSessions({
    String? query,
    String? sessionType,
    String? difficultyLevel,
    String? instructorId,
  }) async {
    try {
      var queryBuilder = _client.from('live_sessions').select('''
        *,
        user_profiles!instructor_id(id, full_name, avatar_url)
      ''').in_('status', ['scheduled', 'live']);

      if (query != null && query.isNotEmpty) {
        queryBuilder =
            queryBuilder.or('title.ilike.%$query%,description.ilike.%$query%');
      }

      if (sessionType != null && sessionType != 'all') {
        queryBuilder = queryBuilder.eq('session_type', sessionType);
      }

      if (difficultyLevel != null && difficultyLevel != 'all') {
        queryBuilder = queryBuilder.eq('difficulty_level', difficultyLevel);
      }

      if (instructorId != null) {
        queryBuilder = queryBuilder.eq('instructor_id', instructorId);
      }

      final response = await queryBuilder
          .order('scheduled_start', ascending: true)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search sessions: ${e.toString()}');
    }
  }
}
