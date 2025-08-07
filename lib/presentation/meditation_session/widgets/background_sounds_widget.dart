import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class BackgroundSoundsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> availableSounds;
  final String? selectedSound;
  final double backgroundVolume;
  final Function(String?) onSoundSelected;
  final Function(double) onVolumeChanged;
  final VoidCallback onClose;

  const BackgroundSoundsWidget({
    Key? key,
    required this.availableSounds,
    required this.selectedSound,
    required this.backgroundVolume,
    required this.onSoundSelected,
    required this.onVolumeChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Background Sounds',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.2)),

          // Volume Control
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Volume',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'volume_down',
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    Expanded(
                      child: Slider(
                        value: backgroundVolume,
                        onChanged: onVolumeChanged,
                        activeColor: AppTheme.lightTheme.colorScheme.secondary,
                        inactiveColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: Colors.white,
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'volume_up',
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sound Options
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: availableSounds.length + 1, // +1 for "None" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  // None option
                  return _buildSoundOption(
                    context,
                    'None',
                    'silence',
                    'No background sound',
                    selectedSound == null,
                    () => onSoundSelected(null),
                  );
                }

                final sound = availableSounds[index - 1];
                return _buildSoundOption(
                  context,
                  sound['name'] as String,
                  sound['icon'] as String,
                  sound['description'] as String,
                  selectedSound == sound['id'],
                  () => onSoundSelected(sound['id'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundOption(
    BuildContext context,
    String name,
    String iconName,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.secondary
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.secondary
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
