import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';

import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_style.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<LumiNotificationItem>> _notificationsFuture;
  final Set<String> _locallyReadIds = {};
  bool _unreadOnly = false;
  bool _markingAll = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = LumiAccountRepository.fetchNotifications();
  }

  void _reload() {
    setState(() {
      _actionError = null;
      _notificationsFuture = LumiAccountRepository.fetchNotifications();
    });
  }

  bool _isRead(LumiNotificationItem item) =>
      item.isRead || _locallyReadIds.contains(item.id);

  Future<void> _markRead(LumiNotificationItem item) async {
    if (_isRead(item)) return;
    setState(() {
      _locallyReadIds.add(item.id);
      _actionError = null;
    });
    try {
      await LumiAccountRepository.markNotificationRead(item.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _locallyReadIds.remove(item.id));
      _showError(error.toString());
    }
  }

  Future<void> _markAllRead(List<LumiNotificationItem> items) async {
    if (_markingAll) return;
    final unread = items.where((item) => !_isRead(item)).toList();
    if (unread.isEmpty) return;
    setState(() {
      _markingAll = true;
      _actionError = null;
      _locallyReadIds.addAll(unread.map((item) => item.id));
    });
    try {
      await LumiAccountRepository.markAllNotificationsRead();
      _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locallyReadIds.removeAll(unread.map((item) => item.id));
        _actionError = error.toString();
      });
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LumiAdaptive.text(error)),
        action: SnackBarAction(label: 'Thử lại', onPressed: _reload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      appBar: AppBar(
        title: Text(
          LumiAdaptive.text('Thông báo'),
          style: LumiAdaptive.style(LumiStyle.heading(size: 30)),
        ),
        actions: [
          IconButton(
            tooltip: LumiAdaptive.optionalText('Tải lại'),
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<LumiNotificationItem>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <LumiNotificationItem>[];
          final unreadCount = items.where((item) => !_isRead(item)).length;
          final visible =
              items.where((item) => !_unreadOnly || !_isRead(item)).toList()
                ..sort((a, b) {
                  final aDate =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });
          final loading = snapshot.connectionState == ConnectionState.waiting;

          if (snapshot.hasError && snapshot.data == null) {
            return _errorState(snapshot.error.toString());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        LumiAdaptive.text(
                          unreadCount == 0
                              ? 'Cập nhật dành cho bạn'
                              : '$unreadCount thông báo chưa đọc',
                        ),
                        style: LumiAdaptive.style(LumiStyle.body(size: 14)),
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: _markingAll
                            ? null
                            : () => _markAllRead(items),
                        child: Text(
                          LumiAdaptive.text(
                            _markingAll
                                ? 'Đang cập nhật...'
                                : 'Đánh dấu đã đọc',
                          ),
                          style: LumiAdaptive.style(
                            LumiStyle.body(
                              size: 13,
                              color: LumiAdaptive.color(
                                LumiStyle.rose,
                                surface: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _filterChip('Tất cả', !_unreadOnly),
                    const SizedBox(width: 10),
                    _filterChip('Chưa đọc', _unreadOnly),
                  ],
                ),
              ),
              if (_actionError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    LumiAdaptive.text(_actionError!),
                    style: LumiAdaptive.style(
                      LumiStyle.body(
                        size: 13,
                        color: LumiAdaptive.color(
                          LumiStyle.rose,
                          surface: true,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: loading && snapshot.data == null
                    ? Center(
                        child: CircularProgressIndicator(
                          color: LumiAdaptive.color(LumiStyle.rose),
                        ),
                      )
                    : visible.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: LumiAdaptive.color(
                          LumiStyle.rose,
                          surface: true,
                        ),
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _notificationCard(visible[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _filterChip(String label, bool selected) => ChoiceChip(
    label: Text(LumiAdaptive.text(label)),
    selected: selected,
    onSelected: (_) => setState(() => _unreadOnly = label == 'Chưa đọc'),
    selectedColor: LumiAdaptive.color(LumiStyle.rose, surface: true),
    backgroundColor: LumiAdaptive.color(LumiStyle.blushSurface, surface: true),
    labelStyle: LumiAdaptive.style(
      LumiStyle.body(
        size: 13,
        color: LumiAdaptive.color(
          selected ? Colors.white : LumiStyle.plum,
          surface: true,
        ),
      ),
    ),
    side: BorderSide.none,
  );

  Widget _errorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: LumiAdaptive.color(LumiStyle.rose),
            size: 44,
          ),
          const SizedBox(height: 14),
          Text(
            LumiAdaptive.text('Không tải được thông báo'),
            style: LumiAdaptive.style(LumiStyle.heading(size: 28)),
          ),
          const SizedBox(height: 8),
          Text(
            LumiAdaptive.text(message),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(LumiStyle.body()),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _reload,
            child: Text(LumiAdaptive.text('Thử lại')),
          ),
        ],
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: LumiAdaptive.color(LumiStyle.blushSurface, surface: true),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: LumiAdaptive.color(LumiStyle.rose),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            LumiAdaptive.text(
              _unreadOnly
                  ? 'Bạn đã xem hết thông báo'
                  : 'Chưa có thông báo nào',
            ),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(LumiStyle.heading(size: 28)),
          ),
          const SizedBox(height: 10),
          Text(
            LumiAdaptive.text(
              _unreadOnly ? 'Thông báo chưa đọc sẽ xuất hiện tại đây.' : 'Lịch hẹn, ưu đãi và cập nhật mới từ LUMI sẽ được gửi đến bạn tại đây.',
            ),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(LumiStyle.body()),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(LumiAdaptive.text('Làm mới')),
          ),
        ],
      ),
    ),
  );

  Widget _notificationCard(LumiNotificationItem item) {
    final read = _isRead(item);
    return Material(
      color: LumiAdaptive.color(
        read ? LumiStyle.surface : LumiStyle.blushSurface,
        surface: true,
      ),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _markRead(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LumiAdaptive.color(LumiStyle.ivory, surface: true),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _iconFor(item.type),
                  color: LumiAdaptive.color(LumiStyle.plum),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LumiAdaptive.text(item.title),
                      style: LumiAdaptive.style(
                        LumiStyle.body(
                          size: 15,
                          color: LumiAdaptive.color(
                            LumiStyle.plum,
                            surface: true,
                          ),
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        LumiAdaptive.text(item.message),
                        style: LumiAdaptive.style(LumiStyle.body(size: 13)),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      LumiAdaptive.text(_formatTime(item.createdAt)),
                      style: LumiAdaptive.style(LumiStyle.body(size: 11)),
                    ),
                  ],
                ),
              ),
              if (!read)
                Padding(
                  padding: EdgeInsets.only(left: 8, top: 5),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: LumiAdaptive.color(
                      LumiStyle.rose,
                      surface: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
      case 'booking':
        return Icons.calendar_month_outlined;
      case 'order':
      case 'purchase':
        return Icons.shopping_bag_outlined;
      case 'promotion':
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Thời gian không khả dụng';
    final local = date.toLocal();
    final difference = DateTime.now().difference(local);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
