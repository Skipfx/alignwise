import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BreathingGuideWidget extends StatefulWidget {
  final bool isActive;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;

  const BreathingGuideWidget({
    super.key,
    required this.isActive,
    this.inhaleSeconds = 4,
    this.holdSeconds = 4,
    this.exhaleSeconds = 4,
  });

  @override
  State<BreathingGuideWidget> createState() => _BreathingGuideWidgetState();
}

class _BreathingGuideWidgetState extends State<BreathingGuideWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _textController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _textOpacityAnimation;

  String _currentPhase = 'Inhale';
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final totalCycleDuration =
        widget.inhaleSeconds + widget.holdSeconds + widget.exhaleSeconds;

    _breathingController = AnimationController(
      duration: Duration(seconds: totalCycleDuration),
      vsync: this,
    );

    _textController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _breathingController.addListener(_updateBreathingPhase);

    if (widget.isActive) {
      _startBreathingCycle();
    }
  }

  void _updateBreathingPhase() {
    final progress = _breathingController.value;
    final totalDuration =
        widget.inhaleSeconds + widget.holdSeconds + widget.exhaleSeconds;
    final currentSecond = (progress * totalDuration).floor();

    String newPhase;
    int newCount;

    if (currentSecond < widget.inhaleSeconds) {
      newPhase = 'Inhale';
      newCount = widget.inhaleSeconds - currentSecond;
    } else if (currentSecond < widget.inhaleSeconds + widget.holdSeconds) {
      newPhase = 'Hold';
      newCount = widget.inhaleSeconds + widget.holdSeconds - currentSecond;
    } else {
      newPhase = 'Exhale';
      newCount = totalDuration - currentSecond;
    }

    if (newPhase != _currentPhase || newCount != _currentCount) {
      setState(() {
        _currentPhase = newPhase;
        _currentCount = newCount;
      });
      _textController.forward().then((_) {
        _textController.reverse();
      });
    }
  }

  void _startBreathingCycle() {
    _breathingController.repeat();
    _textController.forward();
  }

  void _stopBreathingCycle() {
    _breathingController.stop();
    _textController.stop();
  }

  @override
  void didUpdateWidget(BreathingGuideWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startBreathingCycle();
      } else {
        _stopBreathingCycle();
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return SizedBox.shrink();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Container(
                width: 50.w * _breathingAnimation.value,
                height: 50.w * _breathingAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.lightTheme.colorScheme.secondary
                          .withValues(alpha: 0.3),
                      AppTheme.lightTheme.colorScheme.secondary
                          .withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 4.h),
          AnimatedBuilder(
            animation: _textOpacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _textOpacityAnimation.value,
                child: Column(
                  children: [
                    Text(
                      _currentPhase,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _currentCount.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.secondary,
                            fontWeight: FontWeight.w200,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
