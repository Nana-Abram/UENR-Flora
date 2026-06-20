// lib/widgets/app_navbar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class AppNavbar extends StatelessWidget {
  const AppNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kBreakpointMd;
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: kBg,
            border: Border(
              bottom: BorderSide(color: kBorder, width: 0.5),
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
                    const Icon(Icons.eco, size: 20, color: kDeep),
                    const SizedBox(width: 8),
                    Text(
                      kAppName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kDeep,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Nav links (hidden on mobile, replaced by hamburger)
              if (!isMobile) ...[
                _NavLink(label: 'Home',     path: '/',         active: location == '/'),
                _NavLink(label: 'Scan',     path: '/scan',     active: location == '/scan'),
                _NavLink(label: 'Explorer', path: '/explorer', active: location == '/explorer'),
                _NavLink(label: 'Learn',    path: '/learn',    active: location == '/learn'),
                const SizedBox(width: 8),
              ],

              // CTA button — always visible
              ElevatedButton.icon(
                onPressed: () => context.go('/scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: kBRSm),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 14),
                label: const Text('Scan now'),
              ),

              // Hamburger (mobile only)
              if (isMobile) ...[
                const SizedBox(width: 10),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: kTx),
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ],
            ],
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
  final String path;
  final bool active;

  const _NavLink({
    required this.label,
    required this.path,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kDeep.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: kBRSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? kDeep : kMu,
          ),
        ),
      ),
    );
  }
}
