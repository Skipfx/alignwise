import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SessionNotesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> sessionNotes;
  final int currentTime;

  const SessionNotesWidget({
    Key? key,
    required this.sessionNotes,
    required this.currentTime,
  }) : super(key: key);

  @override
  State<SessionNotesWidget> createState() => _SessionNotesWidgetState();
}

class _SessionNotesWidgetState extends State<SessionNotesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _currentNote = '';
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SessionNotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != oldWidget.currentTime) {
      _checkForNoteUpdate();
    }
  }

  void _checkForNoteUpdate() {
    final currentNote = widget.sessionNotes.firstWhere(
      (note) =>
          (note['timestamp'] as int) <= widget.currentTime &&
          widget.currentTime <
              (note['timestamp'] as int) + (note['duration'] as int? ?? 5),
      orElse: () => <String, dynamic>{},
    );

    if (currentNote.isNotEmpty && currentNote['text'] != _currentNote) {
      setState(() {
        _currentNote = currentNote['text'] as String;
        _isVisible = true;
      });
      _fadeController.forward().then((_) {
        Future.delayed(Duration(seconds: currentNote['duration'] as int? ?? 5),
            () {
          if (mounted) {
            _fadeController.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _isVisible = false;
                });
              }
            });
          }
        });
      });
    } else if (currentNote.isEmpty && _isVisible) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
            _currentNote = '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentNote.isEmpty) {
      return SizedBox.shrink();
    }

    return Positioned(
      bottom: 25.h,
      left: 6.w,
      right: 6.w,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _currentNote,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
