import 'package:cloud_firestore/cloud_firestore.dart';

class BookingItem {
  final String id;
  final String? userId;
  final String serviceId;
  final String serviceName;
  final String? categoryId;
  final num price;
  final int durationMinutes;
  final String status; // 'pending' | 'confirmed' | 'approved' | 'completed' | 'cancelled' | 'rejected'
  final String contactName;
  final String contactPhone;
  final DateTime? startAt;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final String? imageUrl;
  final String? staffId;
  final String? roomId;

  const BookingItem({
    required this.id,
    this.userId,
    required this.serviceId,
    required this.serviceName,
    this.categoryId,
    required this.price,
    required this.durationMinutes,
    required this.status,
    required this.contactName,
    required this.contactPhone,
    this.startAt,
    this.createdAt,
    this.cancelledAt,
    this.imageUrl,
    this.staffId,
    this.roomId,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value;
      }
      if (value is Timestamp) {
        return value.toDate().toLocal();
      }
      try {
        final dynamic d = (value as dynamic).toDate();
        if (d is DateTime) {
          return d.toLocal();
        }
      } catch (_) {}
      if (value is String) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    return BookingItem(
      id: (json['id'] ?? json['bookingId'] ?? '').toString(),
      userId: json['userId']?.toString(),
      serviceId: (json['serviceId'] ?? '').toString(),
      serviceName:
          (json['serviceName'] ?? json['serviceTitle'] ?? 'Dịch vụ LUMI')
              .toString(),
      categoryId: json['categoryId']?.toString(),
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationMinutes:
          int.tryParse(json['durationMinutes']?.toString() ?? '60') ?? 60,
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      contactName: (json['contactName'] ?? '').toString(),
      contactPhone: (json['contactPhone'] ?? '').toString(),
      startAt: parseDate(json['startAt']),
      createdAt: parseDate(json['createdAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      imageUrl: json['imageUrl']?.toString(),
      staffId: json['staffId']?.toString(),
      roomId: json['roomId']?.toString(),
    );
  }

  factory BookingItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return BookingItem.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      if (categoryId != null) 'categoryId': categoryId,
      'price': price,
      'durationMinutes': durationMinutes,
      'status': status,
      'contactName': contactName,
      'contactPhone': contactPhone,
      if (startAt != null) 'startAt': Timestamp.fromDate(startAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (staffId != null) 'staffId': staffId,
      if (roomId != null) 'roomId': roomId,
    };
  }

  BookingItem copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? serviceName,
    String? categoryId,
    num? price,
    int? durationMinutes,
    String? status,
    String? contactName,
    String? contactPhone,
    DateTime? startAt,
    DateTime? createdAt,
    DateTime? cancelledAt,
    String? imageUrl,
    String? staffId,
    String? roomId,
  }) {
    return BookingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      startAt: startAt ?? this.startAt,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      imageUrl: imageUrl ?? this.imageUrl,
      staffId: staffId ?? this.staffId,
      roomId: roomId ?? this.roomId,
    );
  }

  /// Có thể hủy nếu trạng thái là pending hoặc confirmed/approved, và thời gian chưa bắt đầu
  bool get isCancellable {
    if (status != 'pending' && status != 'confirmed' && status != 'approved') {
      return false;
    }
    if (startAt == null) {
      return false;
    }
    return startAt!.isAfter(DateTime.now());
  }

  /// Lịch sắp tới: chưa diễn ra hoặc đang diễn ra (bao gồm pending, confirmed, approved)
  bool get isUpcoming {
    if (status != 'pending' && status != 'confirmed' && status != 'approved') {
      return false;
    }
    if (startAt == null) {
      return true;
    }
    return startAt!.isAfter(
      DateTime.now().subtract(const Duration(minutes: 30)),
    );
  }

  /// Lịch sử: đã hoàn thành hoặc đã qua thời gian hẹn (nhưng chưa hủy/từ chối)
  bool get isHistory {
    if (status == 'completed') {
      return true;
    }
    if (status == 'cancelled' || status == 'rejected') {
      return false;
    }
    if (startAt == null) {
      return false;
    }
    return startAt!.isBefore(
      DateTime.now().subtract(const Duration(minutes: 30)),
    );
  }

  /// Đã hủy hoặc bị từ chối
  bool get isCancelled => status == 'cancelled' || status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Đã từ chối';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get formattedPrice {
    if (price <= 0) {
      return 'Liên hệ tư vấn';
    }
    final p = price.toInt().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$p đ';
  }

  String get formattedDate {
    if (startAt == null) {
      return '—';
    }
    final d = startAt!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get formattedTime {
    if (startAt == null) {
      return '—';
    }
    final d = startAt!;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDateTime => '$formattedTime · $formattedDate';
}
