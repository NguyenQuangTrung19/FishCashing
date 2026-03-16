/// Global theme mode notifier for dark mode toggle.
///
/// Uses ValueNotifier pattern (simple, no BLoC overhead).
/// Provides ThemeMode.system / light / dark toggle.
library;

import 'package:flutter/material.dart';

/// Global singleton — safe because it's a simple value holder
final themeNotifier = ThemeNotifier();

/// Lightweight theme notifier, no persistence needed
/// (resets to system on app restart, which is fine for QoL)
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) => value = mode;

  bool get isSystem => value == ThemeMode.system;
  bool get isLight => value == ThemeMode.light;
  bool get isDark => value == ThemeMode.dark;
}
