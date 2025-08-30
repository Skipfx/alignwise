import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class SessionCompletionWidget extends StatefulWidget {
  final String sessionTitle;
  final int sessionDuration;
  final int currentStreak;
  final int totalSessions;
  final VoidCallback onContinue;
  final VoidCallback onRestart;

  const SessionCompletionWidget({
    super.key,
    required this.sessionTitle,
    required this.sessionDuration,
    required this.currentStreak,
    required this.totalSessions,
    required this.onContinue,
    required this.onRestart,
  });

  @override
  State<SessionCompletionWidget> createState() =>
      _SessionCompletionWidgetState();
}

class _SessionCompletionWidgetState extends State<SessionCompletionWidget>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _contentController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebrationSequence();
  }

  void _initializeAnimations() {
    _celebrationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startCelebrationSequence() {
    _celebrationController.forward().then((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _contentController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.sessionDuration ~/ 60;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.9),
            AppTheme.lightTheme.colorScheme.primaryContainer
                .withValues(alpha: 0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebration Icon
            AnimatedBuilder(
              animation: _celebrationAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _celebrationAnimation.value,
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.secondary
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CustomIconWidget(
                      iconName: 'check',
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 4.h),

            // Content
            AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _contentAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _contentAnimation.value) * 50),
                    child: Column(
                      children: [
                        Text(
                          'Session Complete!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'You completed "${widget.sessionTitle}"',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),

                        // Stats Cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              context,
                              'Duration',
                              '${minutes}m',
                              'schedule',
                            ),
                            _buildStatCard(
                              context,
                              'Streak',
                              '${widget.currentStreak}',
                              'local_fire_department',
                            ),
                            _buildStatCard(
                              context,
                              'Total',
                              '${widget.totalSessions}',
                              'self_improvement',
                            ),
                          ],
                        ),

                        SizedBox(height: 6.h),

                        // Action Buttons
                        Column(
                          children: [
                            SizedBox(
                              width: 80.w,
                              child: ElevatedButton(
                                onPressed: widget.onContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.lightTheme.colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Continue',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            SizedBox(
                              width: 80.w,
                              child: OutlinedButton(
                                onPressed: widget.onRestart,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.5)),
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Restart Session',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, String iconName) {
    return Container(
      width: 25.w,
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.secondary,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}