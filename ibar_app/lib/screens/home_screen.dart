import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ibar_app/constants/colors.dart';
import 'package:ibar_app/screens/approvals_screen.dart';
import 'package:ibar_app/screens/queries_screen.dart';
import 'package:ibar_app/widgets/menu_item.dart';

import 'catraca.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMenuOpen = false;
  Widget _currentScreen = const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Bem-vindo!', style: TextStyle(fontSize: 24)),
        SizedBox(height: 16),
        Text('Selecione uma opção no menu.', style: TextStyle(fontSize: 16)),
      ],
    ),
  );

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _navigateTo(String route) {
    setState(() {
      _isMenuOpen = false;
      switch (route) {
        case 'approvals':
          _currentScreen = const ApprovalsScreen();
          break;
        case 'queries':
          _currentScreen = const QueriesScreen();
          break;
        case 'catraca':
          _currentScreen = const Catraca();
          break;
      }
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  late double _startX;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    onHorizontalDragStart: (details) {
      _startX = details.globalPosition.dx;
    },
    onHorizontalDragUpdate: (details) {
      final currentX = details.globalPosition.dx;
      if (currentX - _startX > 50 && _startX < 50 && !_isMenuOpen) {
        _toggleMenu();
      } else if (_startX - currentX > 50 && _isMenuOpen) {
        _toggleMenu();
      }
    },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Stack(
          children: [
            // Conteúdo principal
            _currentScreen,

            // Overlay
            if (_isMenuOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),

            // Menu lateral
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _isMenuOpen ? 0 : -250,
              top: 0,
              bottom: 0,
              width: 250,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: AppColors.primaryDarkColor,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          MenuItem(
                            icon: Icons.check_circle_outline,
                            text: 'Aprovações',
                            onTap: () => _navigateTo('approvals'),
                          ),
                          MenuItem(
                            icon: Icons.search,
                            text: 'Consultas',
                            onTap: () => _navigateTo('queries'),
                          ),
                          MenuItem(
                            icon: Icons.settings,
                            text: 'Catraca',
                            onTap: () => _navigateTo('catraca'),
                          ),
                          MenuItem(
                            icon: Icons.exit_to_app,
                            text: 'Sair',
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        appBar: AppBar(
          title: const Text('IBAR'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _toggleMenu,
          ),
        ),
      )
    );
  }
}