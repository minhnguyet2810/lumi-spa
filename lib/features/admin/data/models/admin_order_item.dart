import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderItem {
  const AdminOrderItem({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.phone,
    required this.shippingAddress,
    this.note = '',
    required this.total,
    this.formattedTotal,
    this.paymentMethod = 'COD',
    this.status = 'pending',
    this.items = const [],
    this.userId = '',
    this.createdAt,
    this.updatedAt,
    this.cancelReason,
  });

  final String id;
  final String customerName;
  final String customerEmail;
  final String phone;
  final String shippingAddress;
  final String note;
  final num total;
  final String? formattedTotal;
  final String paymentMethod;
  final String status;
  final List<Map<String, dynamic>> items;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? cancelReason;

  String get displayTotal {
    if (formattedTotal != null && formattedTotal!.isNotEmpty) {
      return formattedTotal!;
    }
    final p = total.toInt().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
    return '$p đ';
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'confirmed':
      case 'processing':
        return 'Đã duyệt (Đang chuẩn bị)';
      case 'shipping':
      case 'delivering':
        return 'Đang giao hàng';
      case 'completed':
        return 'Đã giao thành công';
      case 'cancelled':
      case 'rejected':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706); // Amber
      case 'confirmed':
      case 'processing':
        return const Color(0xFF2563EB); // Blue
      case 'shipping':
      case 'delivering':
        return const Color(0xFF7C3AED); // Purple
      case 'completed':
        return const Color(0xFF16A34A); // Green
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get formattedCreatedAt {
    if (createdAt == null) return 'Vừa đặt';
    final d = createdAt!;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$hour:$minute · $day/$month/${d.year}';
  }

  String get itemsSummary {
    if (items.isEmpty) return 'Chưa có thông tin sản phẩm';
    return items.map((it) {
      final name = it['name'] ?? it['productName'] ?? 'Sản phẩm';
      final qty = it['quantity'] ?? 1;
      return '$name (x$qty)';
    }).join(', ');
  }

  int get totalQuantity {
    if (items.isEmpty) return 0;
    return items.fold<int>(0, (totalQty, it) {
      final q = it['quantity'];
      if (q is int) return totalQty + q;
      return totalQty + (int.tryParse(q?.toString() ?? '') ?? 1);
    });
  }

  factory AdminOrderItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminOrderItem.fromMap(data, doc.id);
  }

  factory AdminOrderItem.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    num parseTotal(dynamic val) {
      if (val is num) return val;
      if (val is String) {
        final sanitized = val.replaceAll(RegExp(r'[^0-9]'), '');
        return num.tryParse(sanitized) ?? 0;
      }
      return 0;
    }

    List<Map<String, dynamic>> parseItems(dynamic val) {
      if (val is List) {
        return val.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }

    return AdminOrderItem(
      id: data['id']?.toString() ?? data['orderId']?.toString() ?? docId,
      customerName: data['customerName']?.toString() ??
          data['name']?.toString() ??
          'Khách hàng LUMI',
      customerEmail: data['customerEmail']?.toString() ??
          data['email']?.toString() ??
          '',
      phone: data['phone']?.toString() ?? '',
      shippingAddress: data['shippingAddress']?.toString() ??
          data['address']?.toString() ??
          'Tại cửa hàng',
      note: data['note']?.toString() ?? '',
      total: parseTotal(data['total']),
      formattedTotal: data['formattedTotal']?.toString(),
      paymentMethod: data['paymentMethod']?.toString() ?? 'COD',
      status: data['status']?.toString() ?? 'pending',
      items: parseItems(data['items']),
      userId: data['userId']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      cancelReason: data['cancelReason']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'phone': phone,
      'shippingAddress': shippingAddress,
      'note': note,
      'total': total,
      'formattedTotal': formattedTotal,
      'paymentMethod': paymentMethod,
      'status': status,
      'items': items,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (cancelReason != null) 'cancelReason': cancelReason,
    };
  }

  AdminOrderItem copyWith({
    String? status,
    String? cancelReason,
    DateTime? updatedAt,
  }) {
    return AdminOrderItem(
      id: id,
      customerName: customerName,
      customerEmail: customerEmail,
      phone: phone,
      shippingAddress: shippingAddress,
      note: note,
      total: total,
      formattedTotal: formattedTotal,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      items: items,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }
}
