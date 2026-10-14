import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'home_screen.dart';
import 'surahs_screen.dart';
import 'favorites_screen.dart';
import 'more_screen.dart';
import 'player_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SurahsScreen(),
    SizedBox.shrink(), // Index 2 is intercepted by onTap
    FavoritesScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bookOpen),
              label: 'Sourates',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.playCircle),
              label: 'Lecteur',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.heart),
              label: 'Favoris',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.menu),
              label: 'Plus',
            ),
          ],
        ),
      ),
    );
  }
}
