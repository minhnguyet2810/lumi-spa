import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/admin/data/models/admin_staff_shift_model.dart';

void main() {
  group('Admin Staff & Roster Model Tests', () {
    test('StaffMemberItem parses correctly and formats role labels', () {
      final map = {
        'id': 'staff_01',
        'staffId': 'staff_01',
        'name': 'Nguyễn Phương Linh',
        'role': 'specialist',
        'phone': '0912345678',
        'email': 'linh@lumi.vn',
        'branchId': 'central_hub',
        'categories': ['facial', 'relaxation'],
        'isActive': true,
      };

      final staff = StaffMemberItem.fromMap(map, 'staff_01');
      expect(staff.id, 'staff_01');
      expect(staff.name, 'Nguyễn Phương Linh');
      expect(staff.initials, 'NL');
      expect(staff.role, 'specialist');
      expect(staff.roleLabel, 'Kỹ thuật viên');
      expect(staff.displayCategories, contains('Chăm sóc da mặt'));
      expect(staff.displayCategories, contains('Thư giãn dưỡng sinh'));
      expect(staff.isActive, isTrue);
    });

    test('StaffMemberItem formats receptionist and branch manager roles', () {
      final rec = StaffMemberItem.fromMap({'role': 'receptionist', 'name': 'Thu Hà'}, 's2');
      expect(rec.roleLabel, 'Lễ tân');

      final mgr = StaffMemberItem.fromMap({'role': 'branch_manager', 'name': 'Trần Nam'}, 's3');
      expect(mgr.roleLabel, 'Quản lý Chi nhánh');
    });

    test('StaffShiftItem parses from map and evaluates status helpers', () {
      final shiftMap = {
        'id': 'shift_101',
        'shiftId': 'shift_101',
        'staffId': 'staff_01',
        'staffName': 'Nguyễn Phương Linh',
        'role': 'specialist',
        'date': '2026-11-20',
        'shiftType': 'morning',
        'shiftTypeLabel': 'Ca Sáng',
        'timeRange': '08:30 - 14:30',
        'status': 'scheduled',
        'notes': 'Trực phòng VIP',
      };

      final shift = StaffShiftItem.fromMap(shiftMap, 'shift_101');
      expect(shift.shiftId, 'shift_101');
      expect(shift.staffName, 'Nguyễn Phương Linh');
      expect(shift.shiftType, 'morning');
      expect(shift.timeRange, '08:30 - 14:30');
      expect(shift.isScheduled, isTrue);
      expect(shift.isCheckedIn, isFalse);
      expect(shift.statusLabel, 'Đã xếp lịch');
    });

    test('StaffShiftItem evaluates checked_in and completed states', () {
      final checkedInShift = StaffShiftItem.fromMap({'status': 'checked_in', 'date': '2026-11-20', 'shiftType': 'morning'}, 's1');
      expect(checkedInShift.isCheckedIn, isTrue);
      expect(checkedInShift.statusLabel, 'Đang trực');

      final completedShift = StaffShiftItem.fromMap({'status': 'completed', 'date': '2026-11-20', 'shiftType': 'afternoon'}, 's2');
      expect(completedShift.isCompleted, isTrue);
      expect(completedShift.statusLabel, 'Đã hoàn tất');

      final leaveShift = StaffShiftItem.fromMap({'status': 'leave_requested', 'date': '2026-11-20', 'shiftType': 'full'}, 's3');
      expect(leaveShift.isLeaveRequested, isTrue);
      expect(leaveShift.statusLabel, 'Xin nghỉ phép');
    });

    test('HrmKpiStats parses aggregation counts', () {
      final statsMap = {
        'totalStaff': 15,
        'onDutyToday': 8,
        'completedToday': 4,
        'onLeaveToday': 2,
        'pendingLeaveCount': 1,
        'targetDate': '2026-11-20',
      };

      final stats = HrmKpiStats.fromMap(statsMap);
      expect(stats.totalStaff, 15);
      expect(stats.onDutyToday, 8);
      expect(stats.completedToday, 4);
      expect(stats.onLeaveToday, 2);
      expect(stats.pendingLeaveCount, 1);
      expect(stats.targetDate, '2026-11-20');
    });
  });
}
