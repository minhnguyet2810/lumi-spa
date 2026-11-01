import 'models/booking_item.dart';
import 'models/slot_availability.dart';

class BookingSlotCalculator {
  static const List<int> standardHours = [9, 10, 11, 12, 13, 14, 15, 16, 17];

  /// Định mức phòng & chuyên viên tối đa phục vụ cùng lúc theo danh mục (từ backend resource seed)
  static const Map<String, int> defaultCategoryCapacities = {
    'facial': 2,
    'relaxation': 2,
    'body': 2,
    'beauty': 1,
  };

  /// Kiểm tra hai khoảng thời gian có bị trùng nhau không
  static bool isOverlapping({
    required DateTime start1,
    required int durationMinutes1,
    required DateTime start2,
    required int durationMinutes2,
  }) {
    final end1 = start1.add(Duration(minutes: durationMinutes1));
    final end2 = start2.add(Duration(minutes: durationMinutes2));
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  /// Tính toán trạng thái các khung giờ cho một ngày cụ thể
  static List<SlotAvailability> calculateSlots({
    required DateTime date,
    required int durationMinutes,
    String? categoryId,
    required List<BookingItem> existingBookings,
    String? currentUserId,
    DateTime? now,
    Map<String, int>? customCapacities,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final capacities = customCapacities ?? defaultCategoryCapacities;
    final maxCapacity = capacities[categoryId] ?? 2;

    // Lọc các booking có hiệu lực (chưa hủy)
    final activeBookings = existingBookings.where((b) {
      return b.status == 'pending' || b.status == 'confirmed';
    }).toList();

    return standardHours.map((h) {
      final slotStart = DateTime(date.year, date.month, date.day, h);

      // 1. Quá giờ đóng cửa spa (18:00)
      if (h * 60 + durationMinutes > 18 * 60) {
        return SlotAvailability(hour: h, status: SlotStatus.closedExceeded);
      }

      // 2. Đã qua thời gian thực tế
      if (slotStart.isBefore(effectiveNow)) {
        return SlotAvailability(hour: h, status: SlotStatus.past);
      }

      // 3. Trùng lịch của khách hàng hiện tại
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final conflictBooking = activeBookings.firstWhere(
          (b) {
            if (b.startAt == null) return false;
            // Chỉ trùng lịch nếu booking này thuộc về user hiện tại
            final isUserBooking = b.userId == null || b.userId == currentUserId;
            if (!isUserBooking) return false;

            return isOverlapping(
              start1: slotStart,
              durationMinutes1: durationMinutes,
              start2: b.startAt!,
              durationMinutes2: b.durationMinutes,
            );
          },
          orElse: () => const BookingItem(
            id: '',
            serviceId: '',
            serviceName: '',
            price: 0,
            durationMinutes: 0,
            status: '',
            contactName: '',
            contactPhone: '',
          ),
        );

        if (conflictBooking.id.isNotEmpty) {
          return SlotAvailability(
            hour: h,
            status: SlotStatus.userConflict,
            conflictReason:
                'Bạn đã có lịch "${conflictBooking.serviceName}" vào lúc ${conflictBooking.formattedTime}',
          );
        }
      }

      // 4. Kín lịch tại Spa (Hết chuyên viên/phòng theo category)
      int overlappingCategoryBookings = 0;
      for (final b in activeBookings) {
        if (b.startAt == null) continue;
        final matchesCategory =
            categoryId == null ||
            b.categoryId == null ||
            b.categoryId == categoryId;

        if (matchesCategory &&
            isOverlapping(
              start1: slotStart,
              durationMinutes1: durationMinutes,
              start2: b.startAt!,
              durationMinutes2: b.durationMinutes,
            )) {
          overlappingCategoryBookings++;
        }
      }

      if (overlappingCategoryBookings >= maxCapacity) {
        return SlotAvailability(
          hour: h,
          status: SlotStatus.fullyBooked,
          remainingCapacity: 0,
        );
      }

      final remaining = maxCapacity - overlappingCategoryBookings;
      return SlotAvailability(
        hour: h,
        status: SlotStatus.available,
        remainingCapacity: remaining,
      );
    }).toList();
  }
}
