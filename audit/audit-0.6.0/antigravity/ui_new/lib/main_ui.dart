import 'package:flutter/material.dart';

class MainView extends StatefulWidget {
  final bool newStyle;
  const MainView({super.key, required this.newStyle});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.newStyle) {
      // Return Old YomiHub View
      return Container(child: Text("Old Style"));
    }

    // New YomiHub View (Material 3)
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 800)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.library_books), label: Text('Thư viện')),
                NavigationRailDestination(icon: Icon(Icons.update), label: Text('Cập nhật')),
              ],
            ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.library_books), label: 'Thư viện'),
                NavigationDestination(icon: Icon(Icons.update), label: 'Cập nhật'),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    return Center(child: Text('Màn hình $_selectedIndex'));
  }
}
