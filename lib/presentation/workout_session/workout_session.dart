import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/exercise_counter_widget.dart';
import './widgets/exercise_video_widget.dart';
import './widgets/rest_period_widget.dart';
import './widgets/timer_widget.dart';
import './widgets/workout_metrics_widget.dart';

class WorkoutSession extends StatefulWidget {
  const WorkoutSession({Key? key}) : super(key: key);

  @override
  State<WorkoutSession> createState() => _WorkoutSessionState();
}

class _WorkoutSessionState extends State<WorkoutSession>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  Timer? _workoutTimer;
  int _elapsedSeconds = 0;
  int _currentExerciseIndex = 0;
  int _currentReps = 0;
  int _currentWeight = 0;
  int _caloriesBurned = 0;
  int _heartRate = 0;
  bool _isWorkoutActive = false;
  bool _isRestPeriod = false;
  bool _isExerciseActive = false;

  // Mock workout data
  final List<Map<String, dynamic>> workoutExercises = [
    {
      "id": 1,
      "name": "Push-ups",
      "description":
          "Classic upper body exercise targeting chest, shoulders, and triceps",
      "videoUrl":
          "https://images.pexels.com/photos/416809/pexels-photo-416809.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "targetReps": 15,
      "targetSets": 3,
      "restSeconds": 60,
      "duration": 0,
      "isTimeBased": false,
      "instructions": [
        "Start in plank position with hands shoulder-width apart",
        "Lower your body until chest nearly touches the floor",
        "Push back up to starting position",
        "Keep your core engaged throughout the movement"
      ]
    },
    {
      "id": 2,
      "name": "Plank Hold",
      "description": "Core strengthening exercise for stability and endurance",
      "videoUrl":
          "https://images.pexels.com/photos/4162449/pexels-photo-4162449.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "targetReps": 0,
      "targetSets": 1,
      "restSeconds": 45,
      "duration": 60,
      "isTimeBased": true,
      "instructions": [
        "Start in forearm plank position",
        "Keep your body in straight line from head to heels",
        "Engage your core and breathe steadily",
        "Hold the position for the target duration"
      ]
    },
    {
      "id": 3,
      "name": "Squats",
      "description": "Lower body compound exercise for legs and glutes",
      "videoUrl":
          "https://images.pexels.com/photos/4162438/pexels-photo-4162438.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "targetReps": 20,
      "targetSets": 3,
      "restSeconds": 60,
      "duration": 0,
      "isTimeBased": false,
      "instructions": [
        "Stand with feet shoulder-width apart",
        "Lower your body as if sitting back into a chair",
        "Keep your chest up and knees behind toes",
        "Return to standing position"
      ]
    },
    {
      "id": 4,
      "name": "Mountain Climbers",
      "description":
          "High-intensity cardio exercise for full body conditioning",
      "videoUrl":
          "https://images.pexels.com/photos/4162451/pexels-photo-4162451.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "targetReps": 0,
      "targetSets": 1,
      "restSeconds": 90,
      "duration": 45,
      "isTimeBased": true,
      "instructions": [
        "Start in high plank position",
        "Alternate bringing knees to chest rapidly",
        "Keep your core tight and hips level",
        "Maintain steady breathing rhythm"
      ]
    },
    {
      "id": 5,
      "name": "Burpees",
      "description": "Full body exercise combining squat, plank, and jump",
      "videoUrl":
          "https://images.pexels.com/photos/4162440/pexels-photo-4162440.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "targetReps": 10,
      "targetSets": 2,
      "restSeconds": 120,
      "duration": 0,
      "isTimeBased": false,
      "instructions": [
        "Start standing, then squat down and place hands on floor",
        "Jump feet back into plank position",
        "Do a push-up, then jump feet back to squat",
        "Explode up with arms overhead"
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _startWorkoutTimer();
    _simulateHeartRate();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _pageController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isWorkoutActive && !_isRestPeriod) {
        setState(() {
          _elapsedSeconds++;
          _caloriesBurned =
              (_elapsedSeconds * 0.15).round(); // Rough calculation
        });
      }
    });
  }

  void _simulateHeartRate() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isWorkoutActive && !_isRestPeriod) {
        setState(() {
          _heartRate =
              120 + (DateTime.now().millisecond % 40); // Simulate 120-160 BPM
        });
      } else if (_isRestPeriod) {
        setState(() {
          _heartRate =
              90 + (DateTime.now().millisecond % 20); // Lower during rest
        });
      }
    });
  }

  String _formatElapsedTime() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> get _currentExercise =>
      workoutExercises[_currentExerciseIndex];

  void _startExercise() {
    setState(() {
      _isWorkoutActive = true;
      _isExerciseActive = true;
      _isRestPeriod = false;
    });
    HapticFeedback.lightImpact();
  }

  void _pauseExercise() {
    setState(() {
      _isExerciseActive = false;
    });
    HapticFeedback.lightImpact();
  }

  void _nextExercise() {
    if (_currentExerciseIndex < workoutExercises.length - 1) {
      setState(() {
        _isRestPeriod = true;
        _isExerciseActive = false;
        _currentReps = 0;
        _currentWeight = 0;
      });
      HapticFeedback.mediumImpact();
    } else {
      _finishWorkout();
    }
  }

  void _skipRest() {
    setState(() {
      _currentExerciseIndex++;
      _isRestPeriod = false;
      _isExerciseActive = false;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticFeedback.lightImpact();
  }

  void _onRestComplete() {
    setState(() {
      _currentExerciseIndex++;
      _isRestPeriod = false;
      _isExerciseActive = false;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticFeedback.mediumImpact();
  }

  void _finishWorkout() {
    setState(() {
      _isWorkoutActive = false;
      _isExerciseActive = false;
      _isRestPeriod = false;
    });
    _celebrationController.forward();
    HapticFeedback.heavyImpact();

    _showWorkoutCompleteDialog();
  }

  void _showWorkoutCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'emoji_events',
              color: AppTheme.lightTheme.colorScheme.secondary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Workout Complete!',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Amazing job! You\'ve completed your workout session.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration:',
                          style: AppTheme.lightTheme.textTheme.bodyMedium),
                      Text(_formatElapsedTime(),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Calories:',
                          style: AppTheme.lightTheme.textTheme.bodyMedium),
                      Text('$_caloriesBurned kcal',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Exercises:',
                          style: AppTheme.lightTheme.textTheme.bodyMedium),
                      Text(
                          '${workoutExercises.length}/${workoutExercises.length}',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/fitness-tracking');
            },
            child: Text('View Progress'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/dashboard-home');
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit Workout?',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to exit? Your progress will be saved.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue Workout'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/fitness-tracking');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with workout info and close button
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Close button
                  GestureDetector(
                    onTap: _showExitConfirmation,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 5.w,
                      ),
                    ),
                  ),

                  SizedBox(width: 3.w),

                  // Workout info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HIIT Workout Session',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Exercise ${_currentExerciseIndex + 1} of ${workoutExercises.length}',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Emergency pause button
                  GestureDetector(
                    onTap: _isExerciseActive ? _pauseExercise : null,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: _isExerciseActive
                            ? AppTheme.lightTheme.colorScheme.secondary
                                .withValues(alpha: 0.1)
                            : AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'pause',
                        color: _isExerciseActive
                            ? AppTheme.lightTheme.colorScheme.secondary
                            : AppTheme.lightTheme.colorScheme.outline,
                        size: 5.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Workout metrics
            Padding(
              padding: EdgeInsets.all(4.w),
              child: WorkoutMetricsWidget(
                elapsedTime: _formatElapsedTime(),
                caloriesBurned: _caloriesBurned,
                heartRate: _heartRate,
                completedExercises: _currentExerciseIndex,
                totalExercises: workoutExercises.length,
              ),
            ),

            // Main content area
            Expanded(
              child: _isRestPeriod
                  ? _buildRestPeriodContent()
                  : _buildExerciseContent(),
            ),

            // Bottom action button
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getActionButtonCallback(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionButtonColor(),
                    padding: EdgeInsets.symmetric(vertical: 2.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: _getActionButtonIcon(),
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _getActionButtonText(),
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          // Exercise video/demonstration
          ExerciseVideoWidget(
            videoUrl: _currentExercise["videoUrl"],
            exerciseName: _currentExercise["name"],
            isPlaying: _isExerciseActive,
            onPlayPause: _isExerciseActive ? _pauseExercise : _startExercise,
          ),

          SizedBox(height: 3.h),

          // Exercise description
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentExercise["description"],
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Instructions:',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                ...(_currentExercise["instructions"] as List)
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 0.5.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Exercise counters
          if (_currentExercise["isTimeBased"]) ...[
            TimerWidget(
              initialSeconds: _currentExercise["duration"],
              isActive: _isExerciseActive,
              onTimerComplete: _nextExercise,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ExerciseCounterWidget(
                    label: 'REPS',
                    currentValue: _currentReps,
                    targetValue: _currentExercise["targetReps"],
                    onIncrement: () => setState(() => _currentReps++),
                    onDecrement: () => setState(() =>
                        _currentReps = _currentReps > 0 ? _currentReps - 1 : 0),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ExerciseCounterWidget(
                    label: 'WEIGHT (KG)',
                    currentValue: _currentWeight,
                    targetValue: 0,
                    onIncrement: () => setState(() => _currentWeight++),
                    onDecrement: () => setState(() => _currentWeight =
                        _currentWeight > 0 ? _currentWeight - 1 : 0),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildRestPeriodContent() {
    final nextExerciseIndex = _currentExerciseIndex + 1;
    final nextExercise = nextExerciseIndex < workoutExercises.length
        ? workoutExercises[nextExerciseIndex]
        : null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: RestPeriodWidget(
          restSeconds: _currentExercise["restSeconds"],
          nextExerciseName: nextExercise?["name"] ?? "Workout Complete",
          nextExerciseImage: nextExercise?["videoUrl"] ?? "",
          isActive: true,
          onRestComplete: _onRestComplete,
          onSkipRest: _skipRest,
        ),
      ),
    );
  }

  String _getActionButtonText() {
    if (_isRestPeriod) return 'RESTING...';
    if (!_isExerciseActive && !_isWorkoutActive) return 'START EXERCISE';
    if (_isExerciseActive) return 'PAUSE EXERCISE';
    if (_currentExerciseIndex == workoutExercises.length - 1)
      return 'FINISH WORKOUT';
    return 'NEXT EXERCISE';
  }

  String _getActionButtonIcon() {
    if (_isRestPeriod) return 'hourglass_empty';
    if (!_isExerciseActive && !_isWorkoutActive) return 'play_arrow';
    if (_isExerciseActive) return 'pause';
    if (_currentExerciseIndex == workoutExercises.length - 1) return 'flag';
    return 'skip_next';
  }

  Color _getActionButtonColor() {
    if (_isRestPeriod) return AppTheme.lightTheme.colorScheme.outline;
    if (_isExerciseActive) return AppTheme.lightTheme.colorScheme.secondary;
    if (_currentExerciseIndex == workoutExercises.length - 1)
      return AppTheme.lightTheme.colorScheme.tertiary;
    return AppTheme.lightTheme.primaryColor;
  }

  VoidCallback? _getActionButtonCallback() {
    if (_isRestPeriod) return null;
    if (!_isExerciseActive && !_isWorkoutActive) return _startExercise;
    if (_isExerciseActive) return _pauseExercise;
    if (_currentExerciseIndex == workoutExercises.length - 1)
      return _finishWorkout;
    return _nextExercise;
  }
}
