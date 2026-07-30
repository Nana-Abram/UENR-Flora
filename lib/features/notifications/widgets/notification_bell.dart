// lib/features/notifications/widgets/notification_bell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../providers/notification_provider.dart';

const _kBadgeRed = Color(0xFFE53935);

/// Bell icon with an unread-count badge — drop into any AppBar/navbar.
/// Tapping it navigates to /notifications.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;
    final label = count > 9 ? '9+' : '$count';
    final semanticLabel = count > 0 ? 'Notifications, $count unread' : 'Notifications';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: () => context.go('/notifications'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorder, width: 1),
                ),
                child: Icon(Icons.notifications_outlined, size: 17, color: kMu),
              ),
              if (count > 0)
                Positioned(
                  right: -2, top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(color: _kBadgeRed, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
