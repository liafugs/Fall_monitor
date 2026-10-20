import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'history_screen.dart';
import 'monitoring_screen.dart';
import 'settings_screen.dart';
import 'signals_screen.dart';
import 'test_screen.dart';

/// Casca de navegação.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  static const _pages = <Widget>[
    MonitoringScreen(),
    SignalsScreen(),
    HistoryScreen(),
    TestScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(Constants.appName)),
        body: _pages[_i],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.monitor_heart), label: 'Início'),
            NavigationDestination(icon: Icon(Icons.show_chart), label: 'Sinais'),
            NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
            NavigationDestination(icon: Icon(Icons.science), label: 'Testes'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
          ],
        ),
      );
}
