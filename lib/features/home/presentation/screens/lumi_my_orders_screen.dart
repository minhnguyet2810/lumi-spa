import 'lumi_order_ui.dart';
import '../../../../core/theme/lumi_adaptive.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lumi_order_detail_screen.dart';
import '../../../../core/data/lumi_order_store.dart';

class LumiMyOrdersScreen extends StatefulWidget {
  const LumiMyOrdersScreen({super.key});

  @override
  State<LumiMyOrdersScreen> createState() => _LumiMyOrdersScreenState();
}

class _LumiMyOrdersScreenState extends State<LumiMyOrdersScreen> {
  StreamSubscription? _ordersSub;
  StreamSubscription<User?>? _authSub;
  int _accountGeneration = 0;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (_) => _listenFirestoreOrders(),
    );
  }

  @override
  void dispose() {
    _accountGeneration++;
    _ordersSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _listenFirestoreOrders() {
    final generation = ++_accountGeneration;
    _ordersSub?.cancel();
    LumiOrderStore.orders.clear();
    if (mounted) {
      setState(() {});
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    _ordersSub = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted ||
                generation != _accountGeneration ||
                FirebaseAuth.instance.currentUser?.uid != user.uid) {
              return;
            }
            LumiOrderStore.orders.clear();
            for (final doc in snapshot.docs) {
              LumiOrderStore.syncOrderFromFirestore(doc.data(), doc.id);
            }
            setState(() {});
          },
          onError: (Object error) {
            if (!mounted || generation != _accountGeneration) {
              return;
            }
            LumiOrderStore.orders.clear();
            setState(() {});
            debugPrint('Cannot load own orders: $error');
          },
        );
  }

  static const rose = Color(0xFFA5553E);
  static const ink = Color(0xFF403735);
  static const muted = Color(0xFF756863);
  static const cream = Color(0xFFFFF8EF);
  static const blush = Color(0xFFFBE7DC);

  String selectedStatus = 'Tất cả';

  final List<String> statuses = [
    'Tất cả',
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang giao',
    'Đã giao',
    'Đã hủy',
  ];

  List<Map<String, String>> get orders {
    return LumiOrderStore.orders;
  }

  List<Map<String, String>> get filteredOrders {
    if (selectedStatus == 'Tất cả') {
      return orders;
    }

    return orders.where((order) => order['status'] == selectedStatus).toList();
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 65,
            color: LumiAdaptive.color(rose),
          ),
          const SizedBox(height: 15),
          Text(
            LumiAdaptive.text(message),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(ink),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LumiAdaptive.text('Các đơn hàng của bạn sẽ xuất hiện ở đây.'),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(color: LumiAdaptive.color(muted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilter() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = selectedStatus == status;

          return ChoiceChip(
            label: Text(LumiAdaptive.text(status)),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedStatus = status;
              });
            },
            selectedColor: LumiAdaptive.color(rose, surface: true),
            backgroundColor: LumiAdaptive.color(Colors.white, surface: true),
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: LumiAdaptive.color(isSelected ? rose : blush),
            ),
            labelStyle: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(isSelected ? Colors.white : ink),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, Map<String, String> order) {
    final colors = Theme.of(context).colorScheme;
    final status = order['status'] ?? 'Chờ xác nhận';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: LumiOrderUi.panel(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  order['id'] ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                LumiOrderUi.badge(context, status),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              LumiAdaptive.text('Tổng tiền'),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              order['total'] ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 10),
            _infoRow('Ngày đặt', order['date'] ?? ''),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LumiOrderDetailScreen(order: order),
                    ),
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(LumiAdaptive.text('Xem chi tiết')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) =>
      LumiOrderUi.row(context, label, value);

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    final hasOrders = orders.isNotEmpty;
    final hasFilteredOrders = filteredOrders.isNotEmpty;

    return Scaffold(
      backgroundColor: LumiAdaptive.color(cream, surface: true),
      appBar: AppBar(
        backgroundColor: LumiAdaptive.color(cream, surface: true),
        foregroundColor: LumiAdaptive.color(ink),
        elevation: 0,
        title: Text(
          LumiAdaptive.text('Đơn hàng của tôi'),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              color: LumiAdaptive.color(ink),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: !hasOrders
          ? _emptyState('Bạn chưa có đơn hàng nào')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                LumiOrderUi.panel(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        LumiAdaptive.text('Đơn hàng của tôi'),
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        LumiAdaptive.text(
                          'Theo dõi lịch sử mua sắm và trạng thái các đơn hàng của bạn tại LUMI.',
                        ),
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  hero: true,
                ),
                const SizedBox(height: 20),
                _statusFilter(),
                const SizedBox(height: 20),
                if (!hasFilteredOrders)
                  SizedBox(
                    height: 300,
                    child: _emptyState(
                      'Chưa có đơn hàng ở trạng thái "$selectedStatus"',
                    ),
                  )
                else
                  ...filteredOrders.map((order) => _orderCard(context, order)),
              ],
            ),
    );
  }
}
