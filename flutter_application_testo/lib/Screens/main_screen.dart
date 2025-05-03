import 'package:flutter/material.dart';
import 'package:flutter_application_testo/Screens/home_screen.dart';
import 'package:flutter_application_testo/Screens/message_search_screen.dart';
import 'package:flutter_application_testo/Screens/message_details_screen.dart';
import 'package:flutter_application_testo/Screens/log_screen.dart';
import 'package:flutter_application_testo/Screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    MessageSearchScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white, // couleur du fond
        selectedItemColor: Colors.black, // icônes sélectionnées
        unselectedItemColor: Colors.blue, // icônes non sélectionnées
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Recherche'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'profile'),
        ],
      ),
    );
  }
}
