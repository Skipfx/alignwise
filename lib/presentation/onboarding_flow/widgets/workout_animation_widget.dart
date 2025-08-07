import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WorkoutAnimationWidget extends StatefulWidget {
  const WorkoutAnimationWidget({Key? key}) : super(key: key);

  @override
  State<WorkoutAnimationWidget> createState() => _WorkoutAnimationWidgetState();
}

class _WorkoutAnimationWidgetState extends State<WorkoutAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  final List<String> _workoutIcons = [
    'fitness_center',
    'directions_run',
    'self_improvement',
    'sports_gymnastics'
  ];
  int _currentIconIndex = 0;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationController.addListener(() {
      if (_rotationController.value >= 0.25 * (_currentIconIndex + 1) &&
          _currentIconIndex < _workoutIcons.length - 1) {
        setState(() {
          _currentIconIndex++;
        });
      } else if (_rotationController.value >= 1.0) {
        setState(() {
          _currentIconIndex = 0;
        });
      }
    });

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.lightTheme.colorScheme.secondary,
                    AppTheme.lightTheme.colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.secondary
                        .withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _workoutIcons[_currentIconIndex],
                  color: AppTheme.lightTheme.colorScheme.onSecondary,
                  size: 10.w,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}