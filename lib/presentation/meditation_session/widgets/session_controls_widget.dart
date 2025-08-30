import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class SessionControlsWidget extends StatelessWidget {
  final bool isPlaying;
  final double volume;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;
  final Function(double) onVolumeChanged;

  const SessionControlsWidget({
    super.key,
    required this.isPlaying,
    required this.volume,
    required this.onPlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
    required this.onVolumeChanged,
  });

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      child: Column(
        children: [
          // Volume Control
          Row(
            children: [
              CustomIconWidget(
                iconName: 'volume_down',
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: (value) {
                    _triggerHapticFeedback();
                    onVolumeChanged(value);
                  },
                  activeColor: AppTheme.lightTheme.colorScheme.secondary,
                  inactiveColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: Colors.white,
                ),
              ),
              CustomIconWidget(
                iconName: 'volume_up',
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip Backward
              GestureDetector(
                onTap: () {
                  _triggerHapticFeedback();
                  onSkipBackward();
                },
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'replay_10',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // Play/Pause Button
              GestureDetector(
                onTap: () {
                  _triggerHapticFeedback();
                  onPlayPause();
                },
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CustomIconWidget(
                    iconName: isPlaying ? 'pause' : 'play_arrow',
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              // Skip Forward
              GestureDetector(
                onTap: () {
                  _triggerHapticFeedback();
                  onSkipForward();
                },
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'forward_10',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
