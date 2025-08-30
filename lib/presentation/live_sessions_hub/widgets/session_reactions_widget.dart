import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

class SessionReactionsWidget extends StatefulWidget {
  final AnimationController controller;

  const SessionReactionsWidget({
    super.key,
    required this.controller,
  });

  @override
  State<SessionReactionsWidget> createState() => _SessionReactionsWidgetState();
}

class _SessionReactionsWidgetState extends State<SessionReactionsWidget>
    with TickerProviderStateMixin {
  final List<ReactionAnimation> _reactions = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onReactionTriggered);
  }

  void _onReactionTriggered() {
    if (widget.controller.status == AnimationStatus.forward) {
      _addReaction();
    }
  }

  void _addReaction() {
    final reactions = ['❤️', '🔥', '👏', '💪', '🎉', '👍', '💯'];
    final reaction = reactions[_random.nextInt(reactions.length)];

    final animationController = AnimationController(
      duration: Duration(milliseconds: 2000 + _random.nextInt(1000)),
      vsync: this,
    );

    final reactionAnimation = ReactionAnimation(
      emoji: reaction,
      startX: _random.nextDouble() * 80.w,
      controller: animationController,
    );

    setState(() {
      _reactions.add(reactionAnimation);
    });

    animationController.forward().then((_) {
      setState(() {
        _reactions.remove(reactionAnimation);
      });
      animationController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _reactions.map((reaction) {
          return AnimatedBuilder(
            animation: reaction.controller,
            builder: (context, child) {
              final progress = reaction.controller.value;
              final yPosition = 100.h - (progress * 120.h);
              final opacity =
                  progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);
              final scale = 0.5 + (progress * 0.5);

              return Positioned(
                left: reaction.startX,
                bottom: 100.h - yPosition,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      reaction.emoji,
                      style: TextStyle(
                        fontSize: 24.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onReactionTriggered);
    for (final reaction in _reactions) {
      reaction.controller.dispose();
    }
    super.dispose();
  }
}

class ReactionAnimation {
  final String emoji;
  final double startX;
  final AnimationController controller;

  ReactionAnimation({
    required this.emoji,
    required this.startX,
    required this.controller,
  });
}
