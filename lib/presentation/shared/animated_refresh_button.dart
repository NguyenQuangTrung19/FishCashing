/// Animated refresh button for AppBar.
///
/// A styled refresh button with spin animation when pressed.
/// OceanTheme-branded, replaces plain IconButton(icon: Icon(Icons.refresh)).
library;

import 'package:flutter/material.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';

class AnimatedRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const AnimatedRefreshButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Tải lại',
  });

  @override
  State<AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handlePress,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    OceanTheme.oceanPrimary.withValues(alpha: 0.1),
                    OceanTheme.oceanFoam.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                      parent: _controller, curve: Curves.easeInOut),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: OceanTheme.oceanPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
