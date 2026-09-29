import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'diary_screen.dart';
import 'report_screen.dart';
import 'today_screen.dart';
import 'trends_screen.dart';

/// The four main tabs: Oggi, Diario, Andamento, Condividi.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const today = 0;
  static const diary = 1;
  static const trends = 2;
  static const share = 3;

  /// Lets a tab switch to another one.
  static void select(BuildContext context, int index) =>
      context.findAncestorStateOfType<_HomeShellState>()?.select(index);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = HomeShell.today;

  void select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          DiaryScreen(),
          TrendsScreen(),
          ReportScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: l.navToday,
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: l.navDiary,
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: l.navTrends,
          ),
          NavigationDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share_rounded),
            label: l.navShare,
          ),
        ],
      ),
    );
  }
}
