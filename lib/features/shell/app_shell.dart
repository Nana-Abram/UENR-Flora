// lib/features/shell/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/connectivity_provider.dart';
import '../../core/theme_mode_provider.dart';
import '../../widgets/app_navbar.dart';
import '../challenge/providers/challenge_badge_provider.dart';
import '../notifications/providers/notification_provider.dart';
import '../scan/offline_scan_queue.dart';

/// Wraps every screen with the persistent top navigation bar.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // GoRouter's ShellRoute keeps this widget mounted across in-shell
    // navigation (that's the point — state like scroll position survives
    // route changes), which turned out to also mean the whole-app key
    // trick in PlantIdApp (see app.dart) doesn't reliably force *this*
    // widget to rebuild on a theme toggle, even though it does for the
    // routed page content inside it — verified live: the Scaffold's own
    // background stayed on the old color while every card inside it
    // switched. Watching here directly is the same fix already proven for
    // _AppearanceSection: it subscribes this Element to ThemeModeProvider
    // regardless of what its ancestors do.
    context.watch<ThemeModeProvider>();
    return Scaffold(
      backgroundColor: kBg,
      endDrawer: const _MobileDrawer(),
      body: Column(
        children: [
          const AppNavbar(),
          const _OfflineBanner(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Slim, dismiss-free banner shown for as long as the browser reports no
/// connectivity — every screen's own try/catch already turns a failed
/// Supabase call into a generic "couldn't load/save" message, but gives no
/// indication of *why*, and no signal for when it's safe to retry. This
/// gives both at a glance without every screen wiring up its own check.
/// Also doubles as the OfflineScanQueue's status line: once back online
/// with scans still queued, it swaps to a calmer "syncing" message instead
/// of just disappearing, so a scan taken offline doesn't look like it
/// silently vanished while it's still catching up.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final pendingScans = context.watch<OfflineScanQueue>().pendingCount;
    final showSyncing = isOnline && pendingScans > 0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: !isOnline
          ? Container(
              width: double.infinity,
              color: kUnhealthyTx,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 14, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "You're offline; some features may not work until you're back online.",
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : showSyncing
              ? Container(
                  width: double.infinity,
                  color: kGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pendingScans == 1
                            ? 'Syncing 1 scan from while you were offline…'
                            : 'Syncing $pendingScans scans from while you were offline…',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
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
            const Divider(height: 24),
            const _DrawerThemeToggle(),
          ],
        ),
      ),
    );
  }
}

/// Mobile counterpart to the navbar's quick theme toggle — the navbar
/// collapses to this hamburger drawer below 1280px, so without this entry
/// switching themes on a phone would mean a trip to Profile > Appearance.
class _DrawerThemeToggle extends StatelessWidget {
  const _DrawerThemeToggle();

  @override
  Widget build(BuildContext context) {
    // See _ThemeToggleButton's comment in app_navbar.dart — Theme.of(context)
    // instead of AppBrightness so this icon can't lag the actual applied
    // theme by a frame.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: kDeep),
      title: Text(isDark ? 'Switch to light mode' : 'Switch to dark mode',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: () => context
          .read<ThemeModeProvider>()
          .setMode(isDark ? ThemeMode.light : ThemeMode.dark),
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
                decoration: BoxDecoration(color: kUnhealthyTx, shape: BoxShape.circle),
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
