import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SleepSoundsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> sleepSounds;
  final Function(Map<String, dynamic> sound, int? timerMinutes) onSoundPlay;

  const SleepSoundsWidget({
    super.key,
    required this.sleepSounds,
    required this.onSoundPlay,
  });

  @override
  State<SleepSoundsWidget> createState() => _SleepSoundsWidgetState();
}

class _SleepSoundsWidgetState extends State<SleepSoundsWidget> {
  Map<String, dynamic>? _currentlyPlaying;
  int? _selectedTimer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sleep Sounds',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                      ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 18.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: widget.sleepSounds.length,
            itemBuilder: (context, index) {
              final sound = widget.sleepSounds[index];
              final isPlaying = _currentlyPlaying?["id"] == sound["id"];

              return GestureDetector(
                onTap: () => _showTimerDialog(context, sound),
                child: Container(
                  width: 30.w,
                  margin: EdgeInsets.only(right: 3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPlaying
                          ? AppTheme.lightTheme.colorScheme.secondary
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.2),
                      width: isPlaying ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _getSoundColor(sound["category"] as String)
                                .withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: CustomIconWidget(
                                  iconName: _getSoundIcon(
                                      sound["category"] as String),
                                  color: _getSoundColor(
                                      sound["category"] as String),
                                  size: 10.w,
                                ),
                              ),
                              if (isPlaying)
                                Positioned(
                                  top: 2.w,
                                  right: 2.w,
                                  child: Container(
                                    padding: EdgeInsets.all(1.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CustomIconWidget(
                                      iconName: 'play_arrow',
                                      color: Colors.white,
                                      size: 3.w,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(2.w),
                        child: Column(
                          children: [
                            Text(
                              sound["name"] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              sound["category"] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_currentlyPlaying != null) ...[
          SizedBox(height: 2.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.secondary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'pause',
                    color: Colors.white,
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now Playing',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _currentlyPlaying!["name"] as String,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (_selectedTimer != null)
                        Text(
                          'Timer: ${_selectedTimer}min',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentlyPlaying = null;
                      _selectedTimer = null;
                    });
                  },
                  child: CustomIconWidget(
                    iconName: 'stop',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showTimerDialog(BuildContext context, Map<String, dynamic> sound) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Sleep Timer',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How long would you like to play ${sound["name"]}?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 3.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [15, 30, 60, null].map((minutes) {
                return ChoiceChip(
                  label: Text(minutes != null ? '${minutes}min' : 'Continuous'),
                  selected: _selectedTimer == minutes,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimer = selected ? minutes : null;
                    });
                  },
                  selectedColor: AppTheme.lightTheme.colorScheme.secondary
                      .withValues(alpha: 0.2),
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _selectedTimer == minutes
                            ? AppTheme.lightTheme.colorScheme.secondary
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight: _selectedTimer == minutes
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentlyPlaying = sound;
              });
              widget.onSoundPlay(sound, _selectedTimer);
            },
            child: Text(
              'Play',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSoundColor(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return const Color(0xFF4CAF50);
      case 'white noise':
        return const Color(0xFF9E9E9E);
      case 'rain':
        return const Color(0xFF2196F3);
      case 'ocean':
        return const Color(0xFF00BCD4);
      default:
        return AppTheme.lightTheme.colorScheme.tertiary;
    }
  }

  String _getSoundIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return 'park';
      case 'white noise':
        return 'graphic_eq';
      case 'rain':
        return 'grain';
      case 'ocean':
        return 'waves';
      default:
        return 'music_note';
    }
  }
}
