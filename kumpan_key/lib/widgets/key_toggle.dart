import 'package:flutter/material.dart';

/// Large animated key toggle button.
///
/// Shows a key icon with a glowing ring when active.
/// Pulses gently while advertising to indicate activity.
class KeyToggle extends StatefulWidget {
  final bool isActive;
  final bool isConnected;
  final VoidCallback onToggle;
  final String label;
  final String sublabel;

  const KeyToggle({
    super.key,
    required this.isActive,
    required this.isConnected,
    required this.onToggle,
    required this.label,
    required this.sublabel,
  });

  @override
  State<KeyToggle> createState() => _KeyToggleState();
}

class _KeyToggleState extends State<KeyToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(KeyToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !widget.isConnected) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _glowColor {
    if (widget.isConnected) return const Color(0xFF4CAF50);
    if (widget.isActive) return const Color(0xFF2196F3);
    return Colors.transparent;
  }

  Color get _buttonColor {
    if (widget.isConnected) return const Color(0xFF2E7D32);
    if (widget.isActive) return const Color(0xFF1565C0);
    return const Color(0xFF424242);
  }

  Color get _iconColor {
    if (widget.isActive) return Colors.white;
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale =
                  widget.isActive && !widget.isConnected
                      ? _pulseAnimation.value
                      : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _buttonColor,
                boxShadow: [
                  if (widget.isActive)
                    BoxShadow(
                      color: _glowColor.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  if (widget.isActive)
                    BoxShadow(
                      color: _glowColor.withValues(alpha: 0.2),
                      blurRadius: 60,
                      spreadRadius: 16,
                    ),
                ],
                border: Border.all(
                  color: widget.isActive
                      ? _glowColor.withValues(alpha: 0.6)
                      : Colors.white12,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.key_rounded,
                size: 80,
                color: _iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.label,
            key: ValueKey(widget.label),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isActive ? Colors.white : Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.sublabel,
            key: ValueKey(widget.sublabel),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white38,
            ),
          ),
        ),
      ],
    );
  }
}
