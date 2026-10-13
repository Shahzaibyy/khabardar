import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';
import 'activity_screen.dart';
import 'check_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Bottom navigation: Shield, Activity, Check, Settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static void goTo(BuildContext context, int tab) =>
      context.findAncestorStateOfType<_HomeShellState>()?.select(tab);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          ActivityScreen(),
          CheckScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: KColors.mint,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w700,
              color: s.contains(WidgetState.selected)
                  ? KColors.green
                  : KColors.muted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: select,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.shield_outlined, color: KColors.muted),
              selectedIcon: const Icon(Icons.shield, color: KColors.green),
              label: l.t('navShield'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.forum_outlined, color: KColors.muted),
              selectedIcon: const Icon(Icons.forum, color: KColors.green),
              label: l.t('navMessages'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.search, color: KColors.muted),
              selectedIcon: const Icon(Icons.search, color: KColors.green),
              label: l.t('navCheck'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune, color: KColors.muted),
              selectedIcon: const Icon(Icons.tune, color: KColors.green),
              label: l.t('navSettings'),
            ),
          ],
        ),
      ),
    );
  }
}
