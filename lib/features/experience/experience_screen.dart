import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lumi_spa/core/network/lumi_api_client.dart';
import 'package:lumi_spa/core/settings/app_preferences.dart';
import 'package:lumi_spa/core/widgets/lumi_catalog_image.dart';
import 'package:lumi_spa/features/home/presentation/screens/lumi_booking_screen.dart';

import 'experience_widgets.dart';

class LumiExperienceScreen extends StatefulWidget {
  const LumiExperienceScreen({super.key});
  @override
  State<LumiExperienceScreen> createState() => _LumiExperienceScreenState();
}

class _LumiExperienceScreenState extends State<LumiExperienceScreen> {
  Future<List<Map<String, dynamic>>>? _future;
  StreamSubscription<User?>? _auth;
  bool _saving = false;
  String? _uid;
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _reload();
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) {
        return;
      }
      setState(() {
        _uid = user?.uid;
        _reload();
      });
    });
  }

  void _reload() {
    _future = _uid == null
        ? null
        : Future.wait([
            LumiApiClient.instance.get('$experiencePath/preferences'),
            LumiApiClient.instance.get('$experiencePath/favorites'),
            LumiApiClient.instance.get('$experiencePath/history'),
          ]);
  }

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }

  Future<void> _reminders(bool enabled) async {
    setState(() => _saving = true);
    try {
      await LumiApiClient.instance.put(
        '$experiencePath/preferences',
        body: {'remindersEnabled': enabled},
      );
      if (mounted) {
        setState(_reload);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _remove(Map row) async {
    try {
      await LumiApiClient.instance.delete(
        '$experiencePath/favorites/${row['type']}/${Uri.encodeComponent(row['targetId'].toString())}',
      );
      if (mounted) {
        setState(_reload);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _openFavorite(Map row) async {
    final raw = row['item'];
    if (raw is! Map || row['available'] != true) {
      return;
    }
    final item = Map<String, dynamic>.from(raw);
    if (row['type'] == 'service') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => LumiBookingScreen(service: item)),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LumiCatalogImage(item: item, height: 190),
                const SizedBox(height: 16),
                Text(
                  item['name']?.toString() ?? 'LUMI',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${item['price'] ?? '—'} đ'),
                const SizedBox(height: 12),
                Text(item['description']?.toString() ?? ''),
                LumiCatalogActions(type: 'product', item: item),
                Text(
                  ctx.lumiText(
                    'Mở Cửa hàng để thêm sản phẩm vào giỏ.',
                    'Open Shop to add this product to your cart.',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: Text(context.lumiText('Góc riêng của bạn', 'Your LUMI space')),
        actions: [
          IconButton(
            tooltip: context.lumiText('Tải lại', 'Refresh'),
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          tabs: [
            Tab(text: context.lumiText('Yêu thích', 'Favorites')),
            Tab(text: context.lumiText('Trải nghiệm', 'Experiences')),
          ],
        ),
      ),
      body: _future == null
          ? Center(
              child: Text(
                context.lumiText(
                  'Vui lòng đăng nhập để tiếp tục.',
                  'Please sign in to continue.',
                ),
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_uid),
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () => setState(_reload),
                            child: Text(
                              context.lumiText('Thử lại', 'Try again'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final data = snapshot.data!;
                final prefs = data[0]['data'] as Map;
                final favorites = (data[1]['data'] as List)
                    .whereType<Map>()
                    .toList();
                final history = (data[2]['data'] as List)
                    .whereType<Map>()
                    .toList();
                return TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _hero(
                          context.lumiText(
                            'Những điều bạn yêu thích',
                            'Your favorites',
                          ),
                          context.lumiText(
                            'Lưu lại để dễ tìm vào lần ghé sau.',
                            'Keep the things you love close at hand.',
                          ),
                        ),
                        if (favorites.isEmpty)
                          _empty(
                            context.lumiText(
                              'Chạm trái tim ở trang chi tiết để lưu dịch vụ hoặc sản phẩm.',
                              'Tap the heart on a detail page to save a service or product.',
                            ),
                          ),
                        for (final row in favorites)
                          Card(
                            child: ListTile(
                              leading: Icon(
                                row['type'] == 'service'
                                    ? Icons.spa_outlined
                                    : Icons.shopping_bag_outlined,
                              ),
                              title: Text(
                                (row['item'] as Map?)?['name']?.toString() ??
                                    context.lumiText(
                                      'Mục không còn khả dụng',
                                      'Item unavailable',
                                    ),
                              ),
                              subtitle: Text(
                                row['available'] == true
                                    ? context.lumiText(
                                        'Chạm để khám phá',
                                        'Tap to explore',
                                      )
                                    : context.lumiText(
                                        'Bạn có thể xóa mục đã lưu này.',
                                        'You can remove this saved item.',
                                      ),
                              ),
                              onTap: row['available'] == true
                                  ? () => _openFavorite(row)
                                  : null,
                              trailing: IconButton(
                                tooltip: context.lumiText(
                                  'Bỏ yêu thích',
                                  'Remove favorite',
                                ),
                                onPressed: () => _remove(row),
                                icon: const Icon(Icons.favorite_rounded),
                              ),
                            ),
                          ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _hero(
                          context.lumiText(
                            'Hẹn gặp lại tại LUMI',
                            'See you again at LUMI',
                          ),
                          context.lumiText(
                            'Đặt lại, nhận nhắc lịch và chia sẻ cảm nhận.',
                            'Book again, get reminders and share your feedback.',
                          ),
                        ),
                        Card(
                          child: SwitchListTile(
                            value: prefs['remindersEnabled'] == true,
                            onChanged: _saving ? null : _reminders,
                            title: Text(
                              context.lumiText(
                                'Nhắc trước lịch hẹn 1 giờ',
                                'Remind me 1 hour before',
                              ),
                            ),
                            subtitle: Text(
                              context.lumiText(
                                'Áp dụng lịch đã xác nhận. Thông báo đẩy cần quyền trên thiết bị.',
                                'For confirmed appointments. Push alerts require device permission.',
                              ),
                            ),
                          ),
                        ),
                        if (history.isEmpty)
                          _empty(
                            context.lumiText(
                              'Trải nghiệm của bạn sẽ xuất hiện tại đây.',
                              'Your experiences will appear here.',
                            ),
                          ),
                        for (final row in history)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row['name']?.toString() ?? 'LUMI',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _status(
                                      context,
                                      row['status']?.toString() ?? '',
                                    ),
                                  ),
                                  if (row['at'] != null)
                                    Text(_date(context, row['at'].toString())),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      if (row['sourceType'] == 'booking')
                                        OutlinedButton.icon(
                                          onPressed: () => rebookLumi(
                                            context,
                                            row['sourceId'].toString(),
                                          ),
                                          icon: const Icon(
                                            Icons.event_repeat_rounded,
                                          ),
                                          label: Text(
                                            context.lumiText(
                                              'Đặt lại',
                                              'Book again',
                                            ),
                                          ),
                                        ),
                                      if (row['canReview'] == true)
                                        FilledButton.icon(
                                          onPressed: () async {
                                            await reviewLumi(
                                              context,
                                              Map<String, dynamic>.from(row),
                                            );
                                            if (mounted) {
                                              setState(_reload);
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.star_outline_rounded,
                                          ),
                                          label: Text(
                                            context.lumiText(
                                              'Đánh giá',
                                              'Review',
                                            ),
                                          ),
                                        ),
                                      if (row['status'] == 'completed' &&
                                          row['canReview'] == false)
                                        Text(
                                          context.lumiText(
                                            'Đã gửi đánh giá',
                                            'Review submitted',
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
    ),
  );
  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(text, textAlign: TextAlign.center),
  );
  Widget _hero(String title, String subtitle) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.secondaryContainer,
        ],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    ),
  );
}

String _date(BuildContext context, String raw) {
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) {
    return '';
  }
  return '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}';
}

String _status(BuildContext context, String status) => switch (status) {
  'pending' => context.lumiText('Chờ xác nhận', 'Pending'),
  'confirmed' || 'approved' => context.lumiText('Đã xác nhận', 'Confirmed'),
  'completed' => context.lumiText('Đã hoàn tất', 'Completed'),
  'cancelled' ||
  'canceled' ||
  'rejected' => context.lumiText('Đã hủy / Từ chối', 'Cancelled / Declined'),
  _ => context.lumiText('Đang cập nhật', 'Updating'),
};

class LumiAdminDashboard extends StatefulWidget {
  const LumiAdminDashboard({super.key});
  @override
  State<LumiAdminDashboard> createState() => _LumiAdminDashboardState();
}

class _LumiAdminDashboardState extends State<LumiAdminDashboard> {
  late Future<Map<String, dynamic>> _data = LumiApiClient.instance.get(
    '$experiencePath/dashboard',
  );
  void _reload() => setState(
    () => _data = LumiApiClient.instance.get('$experiencePath/dashboard'),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.lumiText('Tổng quan LUMI', 'LUMI overview')),
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: context.lumiText('Tải lại', 'Refresh'),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(snapshot.error.toString()),
            ),
          );
        }
        final data = snapshot.data!['data'] as Map;
        final cards = <(String, String)>[
          (
            context.lumiText('Lịch hôm nay', 'Appointments today'),
            '${data['bookingsToday']}',
          ),
          (
            context.lumiText('Lịch chờ duyệt', 'Pending appointments'),
            '${data['pendingBookings']}',
          ),
          (
            context.lumiText('Đơn chờ xử lý', 'Pending orders'),
            '${data['pendingOrders']}',
          ),
          (
            context.lumiText('Đơn hoàn tất', 'Completed orders'),
            '${data['completedOrders']}',
          ),
          (context.lumiText('Khách hàng', 'Customers'), '${data['customers']}'),
          (
            context.lumiText('Giá trị đơn hoàn tất', 'Completed order value'),
            '${data['completedOrderValue']} đ',
          ),
        ];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${data['today']} · ${context.lumiText('Giờ Việt Nam', 'Vietnam time')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < 320
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: width,
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(card.$1),
                                const SizedBox(height: 10),
                                Text(
                                  card.$2,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              context.lumiText(
                'Giá trị đơn hoàn tất không phải báo cáo tiền thực nhận.',
                'Completed order value is not a cash received report.',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.lumiText(
                'Lịch đã xác nhận sắp tới',
                'Upcoming confirmed appointments',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if ((data['upcoming'] as List).isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  context.lumiText(
                    'Chưa có lịch sắp tới.',
                    'No upcoming appointments.',
                  ),
                ),
              ),
            for (final row in (data['upcoming'] as List).whereType<Map>())
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(row['name'].toString()),
                  subtitle: Text(_date(context, row['at'].toString())),
                ),
              ),
          ],
        );
      },
    ),
  );
}
