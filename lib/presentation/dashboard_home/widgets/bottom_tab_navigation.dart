import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class BottomTabNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomTabNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomTabNavigation> createState() => _BottomTabNavigationState();
}

class _BottomTabNavigationState extends State<BottomTabNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _slideAnimations;

  final List<TabItem> _tabItems = [
    TabItem(iconName: 'home', label: 'Home', route: '/dashboard-home'),
    TabItem(
        iconName: 'fitness_center',
        label: 'Fitness',
        route: '/fitness-tracking'),
    TabItem(
        iconName: 'restaurant',
        label: 'Nutrition',
        route: '/nutrition-tracking'),
    TabItem(
        iconName: 'self_improvement',
        label: 'Mindful',
        route: '/mindfulness-hub'),
    TabItem(iconName: 'person', label: 'Profile', route: '/user-profile'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      _tabItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers
        .map(
          (controller) => Tween<double>(
            begin: 1.0,
            end: 1.2,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          )),
        )
        .toList();

    _slideAnimations = _animationControllers
        .map(
          (controller) => Tween<double>(
            begin: 0.0,
            end: -4.0,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          )),
        )
        .toList();

    // Animate the current tab
    if (widget.currentIndex < _animationControllers.length) {
      _animationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(BottomTabNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Reset previous animation
      if (oldWidget.currentIndex < _animationControllers.length) {
        _animationControllers[oldWidget.currentIndex].reverse();
      }
      // Start new animation
      if (widget.currentIndex < _animationControllers.length) {
        _animationControllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppTheme.lightMint.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.lightMint.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _tabItems.asMap().entries.map((entry) {
              final index = entry.key;
              final tabItem = entry.value;
              final isSelected = widget.currentIndex == index;

              return AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleAnimations[index],
                  _slideAnimations[index],
                ]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimations[index].value),
                    child: Transform.scale(
                      scale: _scaleAnimations[index].value,
                      child: GestureDetector(
                        onTap: () => _handleTabTap(index, tabItem.route),
                        child: Container(
                          width: 16.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? RadialGradient(
                                    colors: [
                                      AppTheme.primaryBlue
                                          .withValues(alpha: 0.1),
                                      AppTheme.accentMint
                                          .withValues(alpha: 0.05),
                                      Colors.transparent,
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(1.5.w),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color: AppTheme.primaryBlue
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      )
                                    : null,
                                child: CustomIconWidget(
                                  iconName: tabItem.iconName,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.darkGrey
                                          .withValues(alpha: 0.6),
                                  size: isSelected ? 6.w : 5.w,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              // Label
                              Text(
                                tabItem.label,
                                style: GoogleFonts.inter(
                                  fontSize: isSelected ? 11 : 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.darkGrey
                                          .withValues(alpha: 0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleTabTap(int index, String route) {
    if (widget.currentIndex != index) {
      widget.onTap(index);
      // Navigate to the corresponding route
      Navigator.pushNamed(context, route);
    }
  }
}

class TabItem {
  final String iconName;
  final String label;
  final String route;

  TabItem({
    required this.iconName,
    required this.label,
    required this.route,
  });
}