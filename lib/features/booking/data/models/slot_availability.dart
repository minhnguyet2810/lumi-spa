enum SlotStatus {
  available, // Còn trống
  userConflict, // Trùng lịch của bạn
  fullyBooked, // Kín chỗ / Hết nhân viên & phòng
  past, // Đã qua giờ
  closedExceeded, // Vượt quá giờ đóng cửa (18:00)
}

class SlotAvailability {
  final int hour;
  final SlotStatus status;
  final int remainingCapacity;
  final String? conflictReason;

  const SlotAvailability({
    required this.hour,
    required this.status,
    this.remainingCapacity = 0,
    this.conflictReason,
  });

  bool get isAvailable => status == SlotStatus.available;

  String get timeText => '${hour.toString().padLeft(2, '0')}:00';

  String get statusBadge {
    switch (status) {
      case SlotStatus.available:
        return remainingCapacity > 1
            ? 'Còn $remainingCapacity slot'
            : (remainingCapacity == 1 ? 'Còn 1 slot' : 'Còn trống');
      case SlotStatus.userConflict:
        return 'Trùng lịch';
      case SlotStatus.fullyBooked:
        return 'Kín chỗ';
      case SlotStatus.past:
        return 'Đã qua';
      case SlotStatus.closedExceeded:
        return 'Quá 18:00';
    }
  }

  String get explanation {
    switch (status) {
      case SlotStatus.available:
        return 'Khung giờ này đang còn trống.';
      case SlotStatus.userConflict:
        return conflictReason ??
            'Bạn đã có một lịch hẹn khác trong khung giờ này.';
      case SlotStatus.fullyBooked:
        return 'Khung giờ này tại spa đã kín phòng hoặc hết chuyên viên.';
      case SlotStatus.past:
        return 'Khung giờ này đã trôi qua, vui lòng chọn giờ sắp tới.';
      case SlotStatus.closedExceeded:
        return 'Dịch vụ cần kết thúc trước giờ đóng cửa (18:00).';
    }
  }
}

