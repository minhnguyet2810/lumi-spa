import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../../booking/data/models/booking_item.dart';

class AdminBookingTable extends StatelessWidget {
  const AdminBookingTable({
    super.key,
    required this.bookings,
    required this.onApprove,
    required this.onReject,
    required this.onTapDetail,
  });

  final List<BookingItem> bookings;
  final void Function(BookingItem item) onApprove;
  final void Function(BookingItem item) onReject;
  final void Function(BookingItem item) onTapDetail;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Text(
          'Không có đơn đặt lịch nào phù hợp.',
          style: GoogleFonts.dmSans(color: LumiStyle.muted, fontSize: 14),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiStyle.line),
        boxShadow: [
          BoxShadow(
            color: LumiStyle.plum.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(LumiStyle.blushSurface),
            headingTextStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: LumiStyle.plum,
            ),
            dataTextStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: LumiStyle.plum,
            ),
            horizontalMargin: 20,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('MÃ ĐƠN')),
              DataColumn(label: Text('KHÁCH HÀNG')),
              DataColumn(label: Text('DỊCH VỤ')),
              DataColumn(label: Text('THỜI GIAN HẸN')),
              DataColumn(label: Text('TỔNG TIỀN')),
              DataColumn(label: Text('TRẠNG THÁI')),
              DataColumn(label: Text('HÀNH ĐỘNG')),
            ],
            rows: bookings.map((item) {
              final isPending = item.status == 'pending';
              final isApproved =
                  item.status == 'approved' || item.status == 'confirmed';
              final isRejected =
                  item.status == 'rejected' || item.status == 'cancelled';

              Color badgeBg;
              Color badgeText;
              String badgeTitle = item.statusLabel;

              if (isPending) {
                badgeBg = Colors.amber.shade50;
                badgeText = Colors.amber.shade900;
                badgeTitle = 'Chờ duyệt';
              } else if (isApproved) {
                badgeBg = Colors.green.shade50;
                badgeText = Colors.green.shade800;
                badgeTitle = 'Đã duyệt';
              } else if (isRejected) {
                badgeBg = Colors.red.shade50;
                badgeText = Colors.red.shade800;
                badgeTitle = 'Từ chối';
              } else {
                badgeBg = LumiStyle.blushSurface;
                badgeText = LumiStyle.plum;
              }

              final shortId = item.id.length > 8
                  ? item.id.substring(0, 8).toUpperCase()
                  : item.id.toUpperCase();

              return DataRow(
                cells: [
                  // 1. Mã đơn
                  DataCell(
                    InkWell(
                      onTap: () => onTapDetail(item),
                      child: Text(
                        '#$shortId',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          color: LumiStyle.rose,
                        ),
                      ),
                    ),
                  ),
                  // 2. Tên khách hàng & SĐT
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.contactName.isNotEmpty
                              ? item.contactName
                              : 'Khách hàng',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.contactPhone.isNotEmpty)
                          Text(
                            item.contactPhone,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: LumiStyle.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 3. Dịch vụ
                  DataCell(
                    Text(
                      item.serviceName,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                    ),
                  ),
                  // 4. Thời gian hẹn
                  DataCell(
                    Text(
                      item.formattedDateTime,
                      style: GoogleFonts.dmSans(color: LumiStyle.plum),
                    ),
                  ),
                  // 5. Giá tiền
                  DataCell(
                    Text(
                      item.formattedPrice,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.rose,
                      ),
                    ),
                  ),
                  // 6. Trạng thái
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: badgeText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        badgeTitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ),
                  // 7. Hành động (Duyệt / Từ chối / Xem)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending) ...[
                          FilledButton.icon(
                            onPressed: () => onApprove(item),
                            icon: const Icon(Icons.check_rounded, size: 14),
                            label: const Text('Duyệt'),
                            style: FilledButton.styleFrom(
                              backgroundColor: LumiStyle.rose,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              textStyle: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => onReject(item),
                            icon: const Icon(Icons.close_rounded, size: 14),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          tooltip: 'Xem chi tiết',
                          onPressed: () => onTapDetail(item),
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: LumiStyle.plum,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
