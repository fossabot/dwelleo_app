import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/dwelleo_nav_bar.dart';

/// Hosts the five bottom-nav branches (Home, Explore, AI Search, Saved,
/// Profile). Lives in app/ — it is composition-root chrome above features.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DwelleoNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the active tab pops that branch to its root —
          // standard iOS/Android bottom-nav behavior.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
