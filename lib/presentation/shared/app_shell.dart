/// Responsive App Shell with NavigationRail (desktop) and BottomNav (mobile).
///
/// Adapts between desktop and mobile layouts based on screen width.
/// Breakpoint: 600dp (standard Material 3 compact/medium boundary).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fishcash_pos/app/router.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/presentation/shared/widgets/store_logo.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = appDestinations.indexWhere((d) => d.path == location);
    return index >= 0 ? index : 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(appDestinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        final selectedIndex = _currentIndex(context);

        if (isDesktop) {
          return _DesktopShell(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            child: child,
          );
        } else {
          return _MobileShell(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            child: child,
          );
        }
      },
    );
  }
}

/// Desktop layout with collapsible NavigationRail
class _DesktopShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const _DesktopShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late final AnimationController _animController;
  late final Animation<double> _animation;

  // Dimensions
  static const double _expandedWidth = 240.0;
  static const double _collapsedWidth = 80.0;
  static const double _expandedLogoWidth = 200.0;
  static const double _collapsedLogoWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // start expanded
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Animated sidebar
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final width = _collapsedWidth +
                  (_expandedWidth - _collapsedWidth) * _animation.value;
              final logoWidth = _collapsedLogoWidth +
                  (_expandedLogoWidth - _collapsedLogoWidth) * _animation.value;

              return Container(
                width: width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      OceanTheme.oceanDeep,
                      OceanTheme.oceanPrimary,
                    ],
                  ),
                  border: Border(
                    right: BorderSide(
                      color: OceanTheme.oceanDeep,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          StoreLogo(
                            width: logoWidth,
                            fit: BoxFit.contain,
                          ),
                          // Show "FishCash" text only when expanded enough
                          if (_animation.value > 0.5) ...[
                            const SizedBox(height: 4),
                            Opacity(
                              opacity: ((_animation.value - 0.5) * 2)
                                  .clamp(0.0, 1.0),
                              child: Text(
                                'FishCash',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Divider(
                      color: Colors.white24,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),

                    // Navigation items
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: appDestinations.asMap().entries.map((e) {
                            final index = e.key;
                            final dest = e.value;
                            final isSelected =
                                index == widget.selectedIndex;

                            return _SidebarItem(
                              icon: isSelected
                                  ? dest.selectedIcon
                                  : dest.icon,
                              label: dest.label,
                              isSelected: isSelected,
                              isExpanded: _animation.value > 0.3,
                              animValue: _animation.value,
                              onTap: () =>
                                  widget.onDestinationSelected(index),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // Toggle button at bottom
                    const Divider(
                      color: Colors.white24,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: _animation.value > 0.3
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.center,
                            children: [
                              AnimatedRotation(
                                turns: _isExpanded ? 0.0 : 0.5,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                child: const Icon(
                                  Icons.keyboard_double_arrow_left,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                              ),
                              if (_animation.value > 0.5) ...[
                                const SizedBox(width: 8),
                                Opacity(
                                  opacity: ((_animation.value - 0.5) * 2)
                                      .clamp(0.0, 1.0),
                                  child: const Text(
                                    'Thu gọn',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Main content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Individual sidebar navigation item with hover + selection effects
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final double animValue;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.animValue,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? Colors.white.withValues(alpha: 0.15)
        : _isHovered
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent;
    final iconColor = widget.isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.6);
    final textColor = widget.isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: widget.isExpanded ? 14 : 0,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      )
                    : null,
              ),
              child: widget.isExpanded
                  ? Row(
                      children: [
                        Icon(widget.icon, color: iconColor, size: 22),
                        if (widget.animValue > 0.5) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Opacity(
                              opacity: ((widget.animValue - 0.3) / 0.7)
                                  .clamp(0.0, 1.0),
                              child: Text(
                                widget.label,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: widget.isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Center(
                      child: Tooltip(
                        message: widget.label,
                        preferBelow: false,
                        child: Icon(widget.icon, color: iconColor, size: 24),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile layout with BottomNavigationBar
class _MobileShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const _MobileShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // On mobile, show only the first 5 destinations to avoid crowding
    final mobileDestinations = appDestinations.take(5).toList();
    final clampedIndex =
        selectedIndex < mobileDestinations.length ? selectedIndex : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: clampedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: mobileDestinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
