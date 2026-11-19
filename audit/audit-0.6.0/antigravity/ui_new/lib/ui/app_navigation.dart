import 'package:flutter/material.dart';

class AppNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AppNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Adaptive for Mobile/Desktop/TV
    bool isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onItemTapped,
        destinations: const [
          NavigationRailDestination(icon: Icon(Icons.library_books), label: Text('Library')),
          NavigationRailDestination(icon: Icon(Icons.update), label: Text('Updates')),
          NavigationRailDestination(icon: Icon(Icons.history), label: Text('History')),
        ],
      );
    } else {
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.library_books), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.update), label: 'Updates'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      );
    }
  }
}
