// lib/features/shell/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../widgets/app_navbar.dart';
import '../challenge/providers/challenge_badge_provider.dart';
import '../notifications/providers/notification_provider.dart';

/// Wraps every screen with the persistent top navigation bar.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      endDrawer: const _MobileDrawer(),
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
  const _MobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const _DrawerLink(label: 'Home',    path: '/',        icon: Icons.home_outlined),
            const _DrawerLink(label: 'Scan',    path: '/scan',    icon: Icons.camera_alt_outlined),
            const _DrawerLink(label: 'Explore', path: '/explorer',icon: Icons.yard_outlined),
            const _DrawerLink(label: 'Learn',   path: '/learn',   icon: Icons.menu_book_outlined),
            Consumer<ChallengeBadgeProvider>(
              builder: (context, badge, _) => _DrawerLink(
                label: 'Challenge', path: '/challenge', icon: Icons.emoji_events_outlined,
                showBadge: badge.showBadge,
              ),
            ),
            Consumer<NotificationProvider>(
              builder: (context, notif, _) => _DrawerLink(
                label: 'Notifications', path: '/notifications', icon: Icons.notifications_outlined,
                showBadge: notif.hasUnread,
              ),
            ),
            const _DrawerLink(label: 'Profile', path: '/profile', icon: Icons.person_outline),
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
  final bool showBadge;

  const _DrawerLink({
    required this.label,
    required this.path,
    required this.icon,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: kDeep),
          if (showBadge)
            Positioned(
              right: -2, top: -2,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: kUnhealthyTx, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        context.go(path);
      },
    );
  }
}
