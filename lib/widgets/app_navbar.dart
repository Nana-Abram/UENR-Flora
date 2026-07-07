// lib/widgets/app_navbar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../features/challenge/providers/challenge_badge_provider.dart';
import '../features/notifications/widgets/notification_bell.dart';

class AppNavbar extends StatelessWidget {
  const AppNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kBreakpointLg;
        return Material(
          color: kWhite,
          elevation: 4,
          shadowColor: Colors.black26,
          child: Container(
            height: 64,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: kBorder, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: kSp24),
            child: Row(
            children: [
              // Logo
              GestureDetector(
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        color: kDeep, shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco, size: 17, color:Colors.white),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontFamily: kFontDisplay,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(text: 'UENR ', style: TextStyle(color: kTx)),
                          TextSpan(text: 'Flora', style: TextStyle(color: kGreen)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 28),

              // Nav links — hidden on narrow widths, replaced by hamburger
              if (!isMobile) ...[
                Expanded(
                  child: Row(
                    children: [
                      _NavLink(label: 'Home', icon: Icons.home_outlined, path: '/', active: location == '/'),
                      _NavLink(label: 'Scan', icon: Icons.camera_alt_outlined, path: '/scan', active: location == '/scan'),
                      _NavLink(label: 'Explore', icon: Icons.explore_outlined, path: '/explorer', active: location == '/explorer'),
                      _NavLink(label: 'Learn', icon: Icons.menu_book_outlined, path: '/learn', active: location == '/learn'),
                      _NavLink(
                        label: 'Challenge',
                        icon: Icons.emoji_events_outlined,
                        path: '/challenge',
                        active: location == '/challenge',
                        showBadge: context.watch<ChallengeBadgeProvider>().showBadge,
                      ),
                      _NavLink(
                        label: 'Profile',
                        icon: location == '/profile' ? Icons.person : Icons.person_outline,
                        path: '/profile',
                        active: location == '/profile',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  height: 38,
                  child: _SearchField(
                    onSubmit: (q) => context.go('/explorer'),
                  ),
                ),
                const SizedBox(width: 12),
                const NotificationBell(),
                const SizedBox(width: 8),
                _IconCircle(
                  icon: Icons.person,
                  filled: true,
                  onTap: () => context.go('/profile'),
                ),
              ] else
                const Spacer(),

              // Hamburger (mobile only)
              if (isMobile) ...[
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: kTx),
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ],
            ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual nav link button
// ─────────────────────────────────────────────────────────────
class _NavLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? path;
  final bool active;
  final bool showBadge;

  const _NavLink({
    required this.label,
    required this.icon,
    required this.path,
    required this.active,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () { if (path != null) context.go(path!); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? kDeep : Colors.transparent,
            borderRadius: kBRPill,

          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 15, color: active ? kWhite : kMu),
                  if (showBadge)
                    Positioned(
                      right: -3, top: -3,
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: kUnhealthyTx, shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? kWhite : kMu,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onSubmit;
  const _SearchField({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: onSubmit,
      style: const TextStyle(fontSize: 13, color: kTx),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search plants...',
        hintStyle: const TextStyle(fontSize: 13, color: kMu),
        prefixIcon: const Icon(Icons.search, size: 17, color: kMu),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: kBRPill,
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kBRPill,
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: kBRPill,
          borderSide: const BorderSide(color: kBorder),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _IconCircle({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: filled ? kDeep : kBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled ?  kBorder :  kBorder,
            width: 1,
          ),
        ),
        child: Icon(icon, size: 17, color: filled ? kMint : kMu),
      ),
    );
  }
}
