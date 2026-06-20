// lib/features/shell/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_navbar.dart';

/// Wraps every screen with the persistent top navigation bar.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // kBg
      endDrawer: _MobileDrawer(),
      body: Column(
        children: [
          const AppNavbar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF5F0E8),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _DrawerLink(label: 'Home',     path: '/',         icon: Icons.home_outlined),
            _DrawerLink(label: 'Scan',     path: '/scan',     icon: Icons.camera_alt_outlined),
            _DrawerLink(label: 'Explorer', path: '/explorer', icon: Icons.yard_outlined),
            _DrawerLink(label: 'Learn',    path: '/learn',    icon: Icons.menu_book_outlined),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  final String label;
  final String path;
  final IconData icon;

  const _DrawerLink({required this.label, required this.path, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A3C2D)),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        context.go(path);
      },
    );
  }
}
