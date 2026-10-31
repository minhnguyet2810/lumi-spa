import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../data/models/admin_user_item.dart';

class AdminUserTable extends StatelessWidget {
  const AdminUserTable({
    super.key,
    required this.users,
    required this.onTapDetail,
  });

  final List<AdminUserItem> users;
  final void Function(AdminUserItem user) onTapDetail;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 48, color: LumiStyle.line),
              const SizedBox(height: 12),
              Text(
                'Không có người dùng nào',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: LumiStyle.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiStyle.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 20,
            columnSpacing: 24,
            headingRowHeight: 52,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 64,
            headingRowColor: WidgetStateProperty.all(LumiStyle.blushSurface),
            columns: [
              DataColumn(
                label: Text(
                  'NGƯỜI DÙNG',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: LumiStyle.plum,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'EMAIL',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: LumiStyle.plum,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'SỐ ĐIỆN THOẠI',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: LumiStyle.plum,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'VAI TRÒ',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: LumiStyle.plum,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'HOẠT ĐỘNG',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: LumiStyle.plum,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'NGÀY THAM GIA',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: LumiStyle.plum,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'THAO TÁC',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: LumiStyle.plum,
                  ),
                ),
              ),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  // Người dùng
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: LumiStyle.plum,
                          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? Text(
                                  user.initials,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: LumiStyle.plum,
                              ),
                            ),
                            Text(
                              'ID: ${user.id.length > 8 ? user.id.substring(0, 8) : user.id}...',
                              style: GoogleFonts.dmSans(fontSize: 10, color: LumiStyle.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Email
                  DataCell(
                    Text(
                      user.email.isNotEmpty ? user.email : '—',
                      style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.plum),
                    ),
                  ),

                  // Phone
                  DataCell(
                    Text(
                      user.phone.isNotEmpty ? user.phone : '—',
                      style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.plum),
                    ),
                  ),

                  // Vai trò
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user.roleBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user.roleLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: user.roleColor,
                        ),
                      ),
                    ),
                  ),

                  // Hoạt động
                  DataCell(
                    Text(
                      '${user.bookingCount} lịch · ${user.orderCount} đơn',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),

                  // Ngày tham gia
                  DataCell(
                    Text(
                      user.formattedCreatedAt,
                      style: GoogleFonts.dmSans(fontSize: 11, color: LumiStyle.muted),
                    ),
                  ),

                  // Thao tác
                  DataCell(
                    IconButton(
                      tooltip: 'Xem hồ sơ',
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: LumiStyle.rose),
                      onPressed: () => onTapDetail(user),
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

