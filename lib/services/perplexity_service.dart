import 'package:dio/dio.dart';

class PerplexityService {
  static final PerplexityService _instance = PerplexityService._internal();
  late final Dio _dio;
  static const String apiKey = String.fromEnvironment('PERPLEXITY_API_KEY');

  factory PerplexityService() {
    return _instance;
  }

  PerplexityService._internal() {
    _initializeService();
  }

  void _initializeService() {
    if (apiKey.isEmpty) {
      throw Exception(
          'PERPLEXITY_API_KEY must be provided via --dart-define-from-file');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.perplexity.ai',
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Dio get dio => _dio;
  String get authApiKey => apiKey;

  /// Generate wellness advice using Perplexity AI
  Future<WellnessAdvice> generateWellnessAdvice({
    required String query,
    String? userContext,
    List<String>? preferences,
  }) async {
    try {
      final prompt = _buildWellnessPrompt(query, userContext, preferences);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'llama-3.1-sonar-small-128k-online',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a wellness expert providing personalized health and fitness advice. Always provide evidence-based recommendations and suggest consulting healthcare professionals for medical concerns.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
          'stream': false,
        },
      );

      if (response.data['choices'] != null &&
          response.data['choices'].isNotEmpty) {
        final content = response.data['choices'][0]['message']['content'];
        return WellnessAdvice.fromResponse(content, query);
      } else {
        throw PerplexityException(
          statusCode: response.statusCode ?? 500,
          message: 'No response generated',
        );
      }
    } on DioException catch (e) {
      throw PerplexityException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ?? e.message,
      );
    }
  }

  /// Search for wellness-related information
  Future<List<WellnessResource>> searchWellnessResources(String query) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'llama-3.1-sonar-small-128k-online',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a wellness research assistant. Provide evidence-based health and fitness resources. Format your response as structured information with sources.'
            },
            {
              'role': 'user',
              'content':
                  'Search for reliable wellness resources about: $query. Provide structured information with sources.'
            }
          ],
          'max_tokens': 800,
          'temperature': 0.3,
          'stream': false,
        },
      );

      if (response.data['choices'] != null &&
          response.data['choices'].isNotEmpty) {
        final content = response.data['choices'][0]['message']['content'];
        return _parseWellnessResources(content);
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw PerplexityException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ?? e.message,
      );
    }
  }

  String _buildWellnessPrompt(
      String query, String? userContext, List<String>? preferences) {
    final buffer = StringBuffer();
    buffer.writeln('Wellness Query: $query');

    if (userContext != null && userContext.isNotEmpty) {
      buffer.writeln('User Context: $userContext');
    }

    if (preferences != null && preferences.isNotEmpty) {
      buffer.writeln('Preferences: ${preferences.join(', ')}');
    }

    buffer.writeln(
        '\nPlease provide personalized wellness advice considering the above information. Include practical tips, potential benefits, and any important safety considerations.');

    return buffer.toString();
  }

  List<WellnessResource> _parseWellnessResources(String content) {
    // Simple parsing - in a real implementation, you might want more sophisticated parsing
    final resources = <WellnessResource>[];
    final lines = content.split('\n');

    String? currentTitle;
    String? currentDescription;
    String? currentSource;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        // Save previous resource if exists
        if (currentTitle != null) {
          resources.add(WellnessResource(
            title: currentTitle,
            description: currentDescription ?? '',
            source: currentSource ?? 'Perplexity AI Research',
          ));
        }
        // Start new resource
        currentTitle = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        currentDescription = null;
        currentSource = null;
      } else if (trimmed.toLowerCase().contains('source:') ||
          trimmed.toLowerCase().contains('reference:')) {
        currentSource = trimmed.replaceFirst(
            RegExp(r'^(source|reference):\s*', caseSensitive: false), '');
      } else if (currentTitle != null && currentDescription == null) {
        currentDescription = trimmed;
      }
    }

    // Add the last resource
    if (currentTitle != null) {
      resources.add(WellnessResource(
        title: currentTitle,
        description: currentDescription ?? '',
        source: currentSource ?? 'Perplexity AI Research',
      ));
    }

    return resources;
  }
}

class WellnessAdvice {
  final String advice;
  final String originalQuery;
  final DateTime timestamp;
  final List<String> keyPoints;
  final List<String> safetyNotes;

  WellnessAdvice({
    required this.advice,
    required this.originalQuery,
    required this.timestamp,
    required this.keyPoints,
    required this.safetyNotes,
  });

  factory WellnessAdvice.fromResponse(String content, String query) {
    final keyPoints = <String>[];
    final safetyNotes = <String>[];

    // Simple parsing for key points and safety notes
    final lines = content.split('\n');
    bool inKeyPoints = false;
    bool inSafetyNotes = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().contains('key points') ||
          trimmed.toLowerCase().contains('main points')) {
        inKeyPoints = true;
        inSafetyNotes = false;
        continue;
      } else if (trimmed.toLowerCase().contains('safety') ||
          trimmed.toLowerCase().contains('caution') ||
          trimmed.toLowerCase().contains('important')) {
        inSafetyNotes = true;
        inKeyPoints = false;
        continue;
      }

      if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
        final point = trimmed.substring(2);
        if (inKeyPoints) {
          keyPoints.add(point);
        } else if (inSafetyNotes) {
          safetyNotes.add(point);
        }
      }
    }

    return WellnessAdvice(
      advice: content,
      originalQuery: query,
      timestamp: DateTime.now(),
      keyPoints: keyPoints,
      safetyNotes: safetyNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advice': advice,
      'original_query': originalQuery,
      'timestamp': timestamp.toIso8601String(),
      'key_points': keyPoints,
      'safety_notes': safetyNotes,
    };
  }
}

class WellnessResource {
  final String title;
  final String description;
  final String source;

  WellnessResource({
    required this.title,
    required this.description,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'source': source,
    };
  }
}

class PerplexityException implements Exception {
  final int statusCode;
  final String message;

  PerplexityException({required this.statusCode, required this.message});

  @override
  String toString() => 'PerplexityException: $statusCode - $message';
}
