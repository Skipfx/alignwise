import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SessionPollWidget extends StatefulWidget {
  final Map<String, dynamic> poll;
  final Function(int) onVote;

  const SessionPollWidget({
    super.key,
    required this.poll,
    required this.onVote,
  });

  @override
  State<SessionPollWidget> createState() => _SessionPollWidgetState();
}

class _SessionPollWidgetState extends State<SessionPollWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  int? _selectedOption;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getPollOptions() {
    try {
      if (widget.poll['options'] is String) {
        return jsonDecode(widget.poll['options']);
      } else if (widget.poll['options'] is Map) {
        return Map<String, dynamic>.from(widget.poll['options']);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  int _getTotalVotes(Map<String, dynamic> options) {
    return options.values
        .fold<int>(0, (sum, votes) => sum + (votes as int? ?? 0));
  }

  void _vote(int optionIndex) {
    if (_hasVoted) return;

    setState(() {
      _selectedOption = optionIndex;
      _hasVoted = true;
    });

    widget.onVote(optionIndex);

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = _getPollOptions();
    if (options.isEmpty) return const SizedBox.shrink();

    final totalVotes = _getTotalVotes(options);
    final optionsList = options.keys.toList();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * -100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(242),
                borderRadius: BorderRadius.circular(4.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poll header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.poll,
                          color: AppTheme.primaryBlue,
                          size: 5.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Poll',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            Text(
                              widget.poll['question'] ?? 'Poll Question',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryLight,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Poll options
                  ...optionsList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final votes = options[option] ?? 0;
                    final percentage =
                        totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
                    final isSelected = _selectedOption == index;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: _buildPollOption(
                        option: option,
                        votes: votes,
                        percentage: percentage,
                        isSelected: isSelected,
                        showResults: _hasVoted,
                        onTap: () => _vote(index),
                      ),
                    );
                  }),

                  // Total votes
                  if (_hasVoted) ...[
                    SizedBox(height: 1.h),
                    Center(
                      child: Text(
                        '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textPrimaryLight.withAlpha(153),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPollOption({
    required String option,
    required int votes,
    required double percentage,
    required bool isSelected,
    required bool showResults,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _hasVoted ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: showResults
              ? (isSelected
                  ? AppTheme.primaryBlue.withAlpha(26)
                  : AppTheme.backgroundLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.textPrimaryLight.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Progress bar background
            if (showResults)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.w),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSelected
                            ? AppTheme.primaryBlue.withAlpha(77)
                            : AppTheme.textPrimaryLight.withAlpha(26),
                      ),
                      minHeight: double.infinity,
                    ),
                  ),
                ),
              ),

            // Option content
            Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                if (showResults) ...[
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '($votes)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textPrimaryLight.withAlpha(153),
                    ),
                  ),
                ] else if (isSelected) ...[
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryBlue,
                    size: 5.w,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}