// lib/features/notifications/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../widgets/breadcrumb.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

String _timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kDeep,
      onRefresh: () => context.read<NotificationProvider>().loadNotifications(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Breadcrumb(current: 'Notifications'),
                      SizedBox(height: 16),
                      _Header(),
                      SizedBox(height: 20),
                      _PushNotificationsCard(),
                      _NotificationList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// A. HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Row(
      children: [
        Text('Notifications',
            style: TextStyle(fontFamily: kFontDisplay, fontSize: 22, fontWeight: FontWeight.w500, color: kTx)),
        if (provider.unreadCount > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: kUnhealthyBg, borderRadius: kBRPill),
            child: Text('${provider.unreadCount} new',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kUnhealthyTx)),
          ),
        ],
        const Spacer(),
        if (provider.unreadCount > 0)
          TextButton(
            onPressed: () => context.read<NotificationProvider>().markAllRead(),
            child: Text('Mark all read',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kGreen)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// A2. WEB PUSH TOGGLE — hidden entirely on unsupported browsers/platforms
// (WebPushService.isSupported is false outside a secure-context web build),
// so there's no dead control offering a feature that can only ever fail.
// ─────────────────────────────────────────────────────────────
class _PushNotificationsCard extends StatelessWidget {
  const _PushNotificationsCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    if (!provider.pushSupported) return const SizedBox.shrink();

    final denied = provider.pushPermission == 'denied';
    final subtitle = denied
        ? "Blocked in your browser's site settings — enable notifications there to turn this back on."
        : provider.pushSubscribed
            ? "You'll get today's challenge reminder even when this tab is closed."
            : 'Get a reminder on this device when a new daily challenge is ready.';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBRXl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: kAccentL, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(Icons.notifications_active_outlined, size: 18, color: kAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Push notifications',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTx)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: kMu, height: 1.4)),
                  ],
                ),
              ),
              if (!denied)
                Semantics(
                  label: 'Push notifications',
                  toggled: provider.pushSubscribed,
                  child: Switch(
                    value: provider.pushSubscribed,
                    activeThumbColor: kAccent,
                    onChanged: provider.pushBusy
                        ? null
                        : (value) => value
                            ? context.read<NotificationProvider>().enablePush()
                            : context.read<NotificationProvider>().disablePush(),
                  ),
                ),
            ],
          ),
          if (provider.pushError != null) ...[
            const SizedBox(height: 10),
            Text(provider.pushError!,
                style: TextStyle(fontSize: 12, color: kUnhealthyTx, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// B/C. LIST / EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _NotificationList extends StatelessWidget {
  const _NotificationList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: kDeep)),
      );
    }

    if (provider.notifications.isEmpty) {
      return const _EmptyState();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final earlierItems = <AppNotification>[];
    for (final n in provider.notifications) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        todayItems.add(n);
      } else if (d == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayItems.isNotEmpty) _DateGroup(label: 'Today', items: todayItems),
        if (yesterdayItems.isNotEmpty) _DateGroup(label: 'Yesterday', items: yesterdayItems),
        if (earlierItems.isNotEmpty) _DateGroup(label: 'Earlier', items: earlierItems),
      ],
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String label;
  final List<AppNotification> items;
  const _DateGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMu, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          ...items.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NotificationCard(notification: n),
              )),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Opacity(
      opacity: n.isRead ? 0.65 : 1.0,
      child: GestureDetector(
        onTap: () {
          context.read<NotificationProvider>().markRead(n.id);
          if (n.actionRoute != null) context.go(n.actionRoute!);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: kBRMd,
            border: Border(
              left: BorderSide(color: n.isRead ? Colors.transparent : kAccent, width: 3),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: n.typeBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(n.iconEmoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTx)),
                    const SizedBox(height: 3),
                    Text(n.body, style: TextStyle(fontSize: 13, color: kMu, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(_timeAgo(n.createdAt), style: TextStyle(fontSize: 11, color: kMu)),
                  ],
                ),
              ),
              if (!n.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: Color(0xFF2979FF), shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text('No notifications yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 6),
          Text("You'll see challenge reminders, achievements, and updates here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kMu)),
        ],
      ),
    );
  }
}
