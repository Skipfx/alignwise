import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/background_sounds_widget.dart';
import './widgets/breathing_guide_widget.dart';
import './widgets/session_completion_widget.dart';
import './widgets/session_controls_widget.dart';
import './widgets/session_notes_widget.dart';
import './widgets/session_progress_widget.dart';

class MeditationSession extends StatefulWidget {
  const MeditationSession({Key? key}) : super(key: key);

  @override
  State<MeditationSession> createState() => _MeditationSessionState();
}

class _MeditationSessionState extends State<MeditationSession>
    with TickerProviderStateMixin {
  // Session state
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _showBreathingGuide = false;
  bool _showBackgroundSounds = false;

  // Audio controls
  double _volume = 0.7;
  double _backgroundVolume = 0.3;
  String? _selectedBackgroundSound;

  // Session timing
  late int _totalDuration;
  late int _remainingTime;
  late int _currentTime;

  // Animation controllers
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  // Session data
  late Map<String, dynamic> _currentSession;

  // Mock session data
  final List<Map<String, dynamic>> _sessions = [
    {
      "id": "meditation_1",
      "title": "Morning Mindfulness",
      "instructor": "Sarah Chen",
      "duration": 600, // 10 minutes "type": "guided",
      "description":
          "Start your day with clarity and intention through this gentle morning meditation practice.",
      "backgroundImage":
          "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "notes": [
        {
          "timestamp": 30,
          "text":
              "Take a moment to settle into your space and find a comfortable position.",
          "duration": 4
        },
        {
          "timestamp": 120,
          "text":
              "Notice the natural rhythm of your breath without trying to change it.",
          "duration": 5
        },
        {
          "timestamp": 300,
          "text":
              "If your mind wanders, gently guide your attention back to the present moment.",
          "duration": 4
        },
        {
          "timestamp": 480,
          "text":
              "Feel gratitude for taking this time to nurture your well-being.",
          "duration": 4
        }
      ]
    }
  ];

  final List<Map<String, dynamic>> _backgroundSounds = [
    {
      "id": "rain",
      "name": "Gentle Rain",
      "icon": "grain",
      "description": "Soft rainfall sounds for deep relaxation"
    },
    {
      "id": "ocean",
      "name": "Ocean Waves",
      "icon": "waves",
      "description": "Rhythmic ocean waves for peaceful meditation"
    },
    {
      "id": "forest",
      "name": "Forest Sounds",
      "icon": "park",
      "description": "Natural forest ambience with birds and wind"
    },
    {
      "id": "white_noise",
      "name": "White Noise",
      "icon": "blur_on",
      "description": "Consistent white noise for focus"
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _initializeAnimations();
    _preventScreenLock();
  }

  void _initializeSession() {
    _currentSession = _sessions.first;
    _totalDuration = _currentSession['duration'] as int;
    _remainingTime = _totalDuration;
    _currentTime = 0;
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.repeat(reverse: true);
  }

  void _preventScreenLock() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _startSession() {
    setState(() {
      _isPlaying = true;
    });
    _startTimer();
  }

  void _pauseSession() {
    setState(() {
      _isPlaying = false;
    });
  }

  void _startTimer() {
    if (_isPlaying && _remainingTime > 0) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted && _isPlaying) {
          setState(() {
            _remainingTime--;
            _currentTime++;
          });

          if (_remainingTime <= 0) {
            _completeSession();
          } else {
            _startTimer();
          }
        }
      });
    }
  }

  void _completeSession() {
    setState(() {
      _isPlaying = false;
      _isCompleted = true;
    });
    HapticFeedback.mediumImpact();
  }

  void _skipBackward() {
    setState(() {
      _currentTime = (_currentTime - 10).clamp(0, _totalDuration);
      _remainingTime = _totalDuration - _currentTime;
    });
  }

  void _skipForward() {
    setState(() {
      _currentTime = (_currentTime + 10).clamp(0, _totalDuration);
      _remainingTime = _totalDuration - _currentTime;
    });
  }

  void _toggleBreathingGuide() {
    setState(() {
      _showBreathingGuide = !_showBreathingGuide;
    });
  }

  void _showBackgroundSoundsPanel() {
    setState(() {
      _showBackgroundSounds = true;
    });
  }

  void _hideBackgroundSoundsPanel() {
    setState(() {
      _showBackgroundSounds = false;
    });
  }

  void _exitSession() {
    _restoreSystemUI();
    Navigator.pop(context);
  }

  void _restartSession() {
    setState(() {
      _isCompleted = false;
      _isPlaying = false;
      _remainingTime = _totalDuration;
      _currentTime = 0;
    });
  }

  void _continueToHub() {
    _restoreSystemUI();
    Navigator.pushReplacementNamed(context, '/mindfulness-hub');
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _restoreSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Scaffold(
        body: SessionCompletionWidget(
          sessionTitle: _currentSession['title'] as String,
          sessionDuration: _totalDuration,
          currentStreak: 7,
          totalSessions: 23,
          onContinue: _continueToHub,
          onRestart: _restartSession,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Animation
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _backgroundAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomImageWidget(
                    imageUrl: _currentSession['backgroundImage'] as String,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          // Dark Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Emergency Exit Button
          Positioned(
            top: 6.h,
            right: 4.w,
            child: SafeArea(
              child: GestureDetector(
                onTap: _exitSession,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Breathing Guide Toggle
          Positioned(
            top: 6.h,
            left: 4.w,
            child: SafeArea(
              child: GestureDetector(
                onTap: _toggleBreathingGuide,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _showBreathingGuide
                        ? AppTheme.lightTheme.colorScheme.secondary
                            .withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'air',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Background Sounds Toggle
          Positioned(
            top: 12.h,
            left: 4.w,
            child: SafeArea(
              child: GestureDetector(
                onTap: _showBackgroundSoundsPanel,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedBackgroundSound != null
                        ? AppTheme.lightTheme.colorScheme.secondary
                            .withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'music_note',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          if (!_showBreathingGuide)
            Center(
              child: SessionProgressWidget(
                totalDuration: _totalDuration,
                remainingTime: _remainingTime,
                sessionTitle: _currentSession['title'] as String,
                instructorName: _currentSession['instructor'] as String,
              ),
            ),

          // Breathing Guide
          if (_showBreathingGuide)
            BreathingGuideWidget(
              isActive: _showBreathingGuide,
              inhaleSeconds: 4,
              holdSeconds: 4,
              exhaleSeconds: 4,
            ),

          // Session Notes
          SessionNotesWidget(
            sessionNotes:
                (_currentSession['notes'] as List).cast<Map<String, dynamic>>(),
            currentTime: _currentTime,
          ),

          // Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SessionControlsWidget(
                isPlaying: _isPlaying,
                volume: _volume,
                onPlayPause: _isPlaying ? _pauseSession : _startSession,
                onSkipBackward: _skipBackward,
                onSkipForward: _skipForward,
                onVolumeChanged: (value) {
                  setState(() {
                    _volume = value;
                  });
                },
              ),
            ),
          ),

          // Background Sounds Panel
          if (_showBackgroundSounds)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BackgroundSoundsWidget(
                availableSounds: _backgroundSounds,
                selectedSound: _selectedBackgroundSound,
                backgroundVolume: _backgroundVolume,
                onSoundSelected: (soundId) {
                  setState(() {
                    _selectedBackgroundSound = soundId;
                  });
                },
                onVolumeChanged: (value) {
                  setState(() {
                    _backgroundVolume = value;
                  });
                },
                onClose: _hideBackgroundSoundsPanel,
              ),
            ),
        ],
      ),
    );
  }
}
