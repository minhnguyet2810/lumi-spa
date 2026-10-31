import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LumiSpaServiceDetailScreen extends StatelessWidget {
  const LumiSpaServiceDetailScreen({
    super.key,
    required this.service,
    required this.category,
    required this.formattedPrice,
    required this.onBook,
  });

  final Map<String, dynamic> service;
  final String category;
  final String formattedPrice;
  final VoidCallback onBook;

  static const cream = Color(0xFFFFFAF8);
  static const rose = Color(0xFFB56F86);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF78676B);

  @override
  Widget build(BuildContext context) {
    final name = (service['name'] ?? 'Dịch vụ LUMI').toString();
    final description = (service['description'] ?? '').toString();
    final duration = service['durationMinutes'];
    final durationText = duration == null ? 'Đang cập nhật' : '$duration phút';
    final detailed = (service['detailedDescription'] ?? '').toString();
    final suitable = (service['suitableFor'] ?? '').toString();
    final steps = service['treatmentSteps'];
    final notes = (service['aftercareNotes'] ?? '').toString();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Chi tiết dịch vụ',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Builder(
                      builder: (context) {
                        final images = service['imageUrls'];
                        String? url;
                        if (images is List) {
                          for (final image in images) {
                            if (image is String && image.trim().isNotEmpty) {
                              url = image.trim();
                              break;
                            }
                          }
                        }
                        final direct = service['imageUrl'];
                        if (url == null &&
                            direct is String &&
                            direct.trim().isNotEmpty) {
                          url = direct.trim();
                        }
                        return url == null
                            ? Image.asset(
                                'assets/images/welcome_spa_3.png',
                                height: 270,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                url,
                                height: 270,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Image.asset(
                                  'assets/images/welcome_spa_3.png',
                                  height: 270,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LUMI SPA & WELLNESS',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      letterSpacing: 1.7,
                      fontWeight: FontWeight.w700,
                      color: rose,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 37,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: blush,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.spa_outlined, color: rose),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Về liệu trình này',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description.trim().isEmpty
                        ? 'LUMI đang cập nhật thông tin chi tiết '
                              'cho liệu trình này.'
                        : description,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      height: 1.65,
                      color: muted,
                    ),
                  ),
                  if (detailed.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      detailed,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.65,
                        color: muted,
                      ),
                    ),
                  ],
                  if (service['benefits'] is List &&
                      (service['benefits'] as List).isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text(
                      'Lợi ích nổi bật',
                      style: GoogleFonts.dmSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final benefit in (service['benefits'] as List))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 19,
                              color: rose,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                benefit.toString(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (steps is List && steps.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    Text(
                      'Quy trình trải nghiệm',
                      style: GoogleFonts.dmSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 29,
                              height: 29,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: blush,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.dmSans(
                                  color: rose,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  steps[i].toString(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (suitable.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Phù hợp với ai?',
                      style: GoogleFonts.dmSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      suitable,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.6,
                        color: muted,
                      ),
                    ),
                  ],
                  if (notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: blush,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: rose,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lưu ý quan trọng',
                                style: GoogleFonts.dmSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            notes,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              height: 1.6,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.schedule_outlined,
                          'Thời lượng',
                          durationText,
                        ),
                        const Divider(height: 28),
                        _infoRow(
                          Icons.payments_outlined,
                          'Giá dịch vụ',
                          formattedPrice,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Bạn có thể xem dịch vụ mà không cần '
                    'đăng nhập. Khi đặt lịch, LUMI sẽ '
                    'yêu cầu đăng nhập để tiếp tục.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: cream,
                border: Border(top: BorderSide(color: Color(0xFFEADCE0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: rose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đặt lịch dịch vụ',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: ink, size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 15, color: muted),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}
