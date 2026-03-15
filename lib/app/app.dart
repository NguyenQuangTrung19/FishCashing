/// Main application widget.
library;

import 'package:flutter/material.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/app/router.dart';

class FishCashApp extends StatelessWidget {
  const FishCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FishCash POS',
      debugShowCheckedModeBanner: false,
      theme: OceanTheme.light,
      darkTheme: OceanTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
