import '../../../../core/widgets/lumi_catalog_image.dart';
import '../../../../core/theme/lumi_adaptive.dart';

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

  static const cream = Color(0xFFFFF8EF);
  static const rose = Color(0xFFA5553E);
  static const blush = Color(0xFFFBE7DC);
  static const blue = Color(0xFFEAF3F7);
  static const ink = Color(0xFF403735);
  static const muted = Color(0xFF756863);

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    final name = (service['name'] ?? 'Dịch vụ LUMI').toString();
    final description = (service['description'] ?? '').toString();
    final duration = service['durationMinutes'];
    final durationText = duration == null ? 'Đang cập nhật' : '$duration phút';
    final detailed = (service['detailedDescription'] ?? '').toString();
    final suitable = (service['suitableFor'] ?? '').toString();
    final steps = service['treatmentSteps'];
    final notes = (service['aftercareNotes'] ?? '').toString();

    return Scaffold(
      backgroundColor: LumiAdaptive.color(cream, surface: true),
      appBar: AppBar(
        backgroundColor: LumiAdaptive.color(cream, surface: true),
        foregroundColor: LumiAdaptive.color(ink),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          LumiAdaptive.text('Chi tiết dịch vụ'),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: LumiAdaptive.color(ink),
            ),
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
                    child: LumiCatalogImage(item: service, height: 270),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    LumiAdaptive.text('LUMI SPA & WELLNESS'),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontSize: 14,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w700,
                        color: LumiAdaptive.color(rose),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    LumiAdaptive.text(name),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontSize: 37,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: LumiAdaptive.color(ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: LumiAdaptive.color(blush, surface: true),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.spa_outlined,
                          color: LumiAdaptive.color(rose),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            LumiAdaptive.text(category),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: LumiAdaptive.color(ink),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    LumiAdaptive.text('Về liệu trình này'),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: LumiAdaptive.color(ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LumiAdaptive.text(
                      description.trim().isEmpty
                          ? 'LUMI đang cập nhật thông tin chi tiết '
                                'cho liệu trình này.'
                          : description,
                    ),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontSize: 16,
                        height: 1.65,
                        color: LumiAdaptive.color(muted),
                      ),
                    ),
                  ),
                  if (detailed.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      LumiAdaptive.text(detailed),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 15,
                          height: 1.65,
                          color: LumiAdaptive.color(muted),
                        ),
                      ),
                    ),
                  ],
                  if (service['benefits'] is List &&
                      (service['benefits'] as List).isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text(
                      LumiAdaptive.text('Lợi ích nổi bật'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: LumiAdaptive.color(ink),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final benefit in (service['benefits'] as List))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 19,
                              color: LumiAdaptive.color(rose),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                LumiAdaptive.text(benefit.toString()),
                                style: LumiAdaptive.style(
                                  GoogleFonts.dmSans(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: LumiAdaptive.color(muted),
                                  ),
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
                      LumiAdaptive.text('Quy trình trải nghiệm'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: LumiAdaptive.color(ink),
                        ),
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
                                color: LumiAdaptive.color(blush, surface: true),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                LumiAdaptive.text('${i + 1}'),
                                style: LumiAdaptive.style(
                                  GoogleFonts.dmSans(
                                    color: LumiAdaptive.color(rose),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  LumiAdaptive.text(steps[i].toString()),
                                  style: LumiAdaptive.style(
                                    GoogleFonts.dmSans(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: LumiAdaptive.color(ink),
                                    ),
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
                      LumiAdaptive.text('Phù hợp với ai?'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: LumiAdaptive.color(ink),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      LumiAdaptive.text(suitable),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 15,
                          height: 1.6,
                          color: LumiAdaptive.color(muted),
                        ),
                      ),
                    ),
                  ],
                  if (notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LumiAdaptive.color(blush, surface: true),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: LumiAdaptive.color(rose),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                LumiAdaptive.text('Lưu ý quan trọng'),
                                style: LumiAdaptive.style(
                                  GoogleFonts.dmSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: LumiAdaptive.color(ink),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            LumiAdaptive.text(notes),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontSize: 14,
                                height: 1.6,
                                color: LumiAdaptive.color(ink),
                              ),
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
                      color: LumiAdaptive.color(blue, surface: true),
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
                    LumiAdaptive.text(
                      'Bạn có thể xem dịch vụ mà không cần '
                      'đăng nhập. Khi đặt lịch, LUMI sẽ '
                      'yêu cầu đăng nhập để tiếp tục.',
                    ),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.5,
                        color: LumiAdaptive.color(muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: LumiAdaptive.color(cream),
                border: Border(
                  top: BorderSide(color: LumiAdaptive.color(Color(0xFFEADFD5))),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onBook,
                  style: LumiAdaptive.style(
                    FilledButton.styleFrom(
                      backgroundColor: LumiAdaptive.color(rose, surface: true),
                      foregroundColor: LumiAdaptive.color(Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        LumiAdaptive.text('Đặt lịch dịch vụ'),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
        Icon(icon, color: LumiAdaptive.color(ink), size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            LumiAdaptive.text(label),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 15,
                color: LumiAdaptive.color(muted),
              ),
            ),
          ),
        ),
        Flexible(
          child: Text(
            LumiAdaptive.text(value),
            textAlign: TextAlign.right,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: LumiAdaptive.color(ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
