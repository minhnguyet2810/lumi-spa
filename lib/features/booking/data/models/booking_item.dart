class BookingItem {
  final String id;
  final String serviceId;
  final String serviceName;
  final String? categoryId;
  final num price;
  final int durationMinutes;
  final String status; // 'pending' | 'confirmed' | 'completed' | 'cancelled'
  final String contactName;
  final String contactPhone;
  final DateTime? startAt;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final String? imageUrl;

  const BookingItem({
    required this.id,
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
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    return BookingItem(
      id: (json['id'] ?? json['bookingId'] ?? '').toString(),
      serviceId: (json['serviceId'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? json['serviceTitle'] ?? 'Dịch vụ LUMI').toString(),
      categoryId: json['categoryId']?.toString(),
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationMinutes: int.tryParse(json['durationMinutes']?.toString() ?? '60') ?? 60,
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      contactName: (json['contactName'] ?? '').toString(),
      contactPhone: (json['contactPhone'] ?? '').toString(),
      startAt: parseDate(json['startAt']),
      createdAt: parseDate(json['createdAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  bool get isCancellable {
    if (status != 'pending' && status != 'confirmed') return false;
    if (startAt == null) return false;
    return startAt!.isAfter(DateTime.now());
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get formattedPrice {
    if (price <= 0) return 'Liên hệ tư vấn';
    final p = price.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
    return '$p đ';
  }

  String get formattedDate {
    if (startAt == null) return '—';
    final d = startAt!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get formattedTime {
    if (startAt == null) return '—';
    final d = startAt!;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDateTime => '$formattedTime · $formattedDate';
}
