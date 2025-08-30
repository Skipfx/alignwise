import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AchievementBadge extends StatefulWidget {
  final String title;
  final String description;
  final String iconName;
  final Color badgeColor;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.badgeColor,
    required this.isUnlocked,
    this.unlockedDate,
    this.onTap,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isUnlocked) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 28.w,
        margin: EdgeInsets.all(2.w),
        child: Column(
          children: [
            // Badge Icon
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isUnlocked ? _scaleAnimation.value : 1.0,
                  child: Transform.rotate(
                    angle: widget.isUnlocked
                        ? _rotationAnimation.value * 0.1
                        : 0.0,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.isUnlocked
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  widget.badgeColor,
                                  widget.badgeColor.withValues(alpha: 0.7),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.withValues(alpha: 0.3),
                                  Colors.grey.withValues(alpha: 0.2),
                                ],
                              ),
                        boxShadow: widget.isUnlocked
                            ? [
                                BoxShadow(
                                  color:
                                      widget.badgeColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                        border: Border.all(
                          color: widget.isUnlocked
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: widget.iconName,
                          color: widget.isUnlocked
                              ? Colors.white
                              : Colors.grey.withValues(alpha: 0.5),
                          size: 8.w.clamp(24.0, 32.0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 1.h),
            // Badge Title
            Text(
              widget.title,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                color: widget.isUnlocked
                    ? AppTheme.lightTheme.colorScheme.onSurface
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            // Badge Description
            Text(
              widget.description,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: widget.isUnlocked
                    ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                fontSize: 9.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.isUnlocked && widget.unlockedDate != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                'Unlocked ${_formatDate(widget.unlockedDate!)}',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: widget.badgeColor,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
