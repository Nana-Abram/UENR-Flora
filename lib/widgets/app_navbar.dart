// lib/widgets/app_navbar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_mode_provider.dart';
import '../core/navigation.dart';
import '../features/challenge/providers/challenge_badge_provider.dart';
import '../features/notifications/widgets/notification_bell.dart';

class AppNavbar extends StatelessWidget {
  const AppNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    // Explicit watch (same fix/rationale as AppShell's) rather than relying
    // on PlantIdApp's whole-tree key-rebuild on toggle — belt-and-braces so
    // this icon is never one toggle behind.
    context.watch<ThemeModeProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Deliberately higher than kBreakpointLg (960) — the full desktop
        // nav here is six links plus a search field plus two icon buttons,
        // which measured out to needing ~1250px to lay out without
        // overflowing. A shared breakpoint tuned for other screens'
        // (lighter) content was letting this render in the 960-1250px
        // range common for a "half-maximized" laptop window, clipping the
        // rightmost links. This constant is local to the navbar rather
        // than raising kBreakpointLg itself, which other screens key off
        // for their own (correctly-fitting) layouts.
        const kNavbarCollapseWidth = 1280.0;
        final isMobile = constraints.maxWidth < kNavbarCollapseWidth;
        return Material(
          color: kWhite,
          elevation: 4,
          shadowColor: Colors.black26,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
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
                      decoration: BoxDecoration(
                        color: kDeep, shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco, size: 17, color:Colors.white),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
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
                // A plain, non-flex SizedBox on purpose: this Row already
                // has one flex child (the nav-links Expanded above), which
                // tight-fits to absorb 100% of the leftover space so the
                // search field + bell + profile icon pack flush against the
                // far right edge. Wrapping this in a second flex widget
                // (Flexible) split that leftover space between the two,
                // and since the search field never actually needed its
                // full share (capped at 220 either way), the unclaimed
                // remainder just went unused — visibly shifting the whole
                // right-hand cluster away from the edge instead of hugging
                // it. isMobile already guarantees >=1280px here, comfortably
                // wide enough for a fixed 220px field.
                SizedBox(
                  width: 220,
                  height: 38,
                  child: _SearchField(
                    onSubmit: (q) => context.go(explorerSearchPath(q)),
                  ),
                ),
                const SizedBox(width: 12),
                const _ThemeToggleButton(),
                const SizedBox(width: 8),
                const NotificationBell(),
                const SizedBox(width: 8),
                _IconCircle(
                  icon: location == '/profile' ? Icons.person : Icons.person_outline,
                  filled: location == '/profile',
                  label: 'Profile',
                  onTap: () => context.go('/profile'),
                ),
              ] else
                const Spacer(),

              // Hamburger (mobile only)
              if (isMobile) ...[
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(Icons.menu, color: kTx),
                    tooltip: 'Open menu',
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
                        decoration: BoxDecoration(
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

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  const _SearchField({required this.onSubmit});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onSubmitted: _submit,
      style: TextStyle(fontSize: 13, color: kTx),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search plants...',
        hintStyle: TextStyle(fontSize: 13, color: kMu),
        prefixIcon: Icon(Icons.search, size: 17, color: kMu),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: kBRPill,
          borderSide: BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kBRPill,
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: kBRPill,
          borderSide: BorderSide(color: kBorder),
        ),
      ),
    );
  }
}

/// Quick light/dark toggle — flips between the two explicit modes
/// directly, skipping "System" for a one-tap switch. The full
/// System/Light/Dark control still lives in Profile > Appearance for
/// anyone who wants to follow the OS setting instead.
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    // Reads Flutter's own resolved Theme rather than the app's custom
    // AppBrightness static — Theme.of(context) is kept correct by Flutter's
    // ordinary InheritedWidget propagation on every rebuild, whereas
    // AppBrightness only updates when PlantIdApp's whole-tree
    // key(AppBrightness.isDark)-triggered rebuild actually runs (see
    // app.dart) — a live check found that swap can lag by a frame for a
    // freshly-inflated icon, leaving this button showing the wrong
    // (pre-toggle) icon even though the rest of the app had already
    // switched. Theme.of(context) can't lag the same way since it doesn't
    // depend on that mechanism at all.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _IconCircle(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onTap: () => context
          .read<ThemeModeProvider>()
          .setMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final String label;
  final VoidCallback onTap;

  const _IconCircle({
    required this.icon,
    required this.onTap,
    required this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: filled ? kDeep : kBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: kBorder, width: 1),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 17, color: filled ? kMint : kMu),
            ),
          ),
        ),
      ),
    );
  }
}
