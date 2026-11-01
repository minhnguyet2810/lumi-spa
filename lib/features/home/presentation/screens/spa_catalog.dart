import '../../../../core/widgets/lumi_catalog_image.dart';
import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spa_service_detail_screen.dart';

class LumiSpaCatalog extends StatefulWidget {
  const LumiSpaCatalog({
    super.key,
    required this.servicesFuture,
    required this.onRefresh,
    required this.onBook,
  });
  final Future<List<Map<String, dynamic>>> servicesFuture;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onBook;
  @override
  State<LumiSpaCatalog> createState() => _LumiSpaCatalogState();
}

class _LumiSpaCatalogState extends State<LumiSpaCatalog> {
  static const ink = Color(0xFF403735);
  static const rose = Color(0xFFA5553E);
  static const blue = Color(0xFFEAF3F7);
  static const blush = Color(0xFFFBE7DC);
  static const muted = Color(0xFF756863);
  final _search = TextEditingController();
  String _category = 'Tất cả';
  final categories = const [
    'Tất cả',
    'Da mặt',
    'Thư giãn',
    'Cơ thể',
    'Thẩm mỹ',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String categoryOf(Map<String, dynamic> service) {
    final categoryId = (service['categoryId'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    switch (categoryId) {
      case 'facial':
        return 'Da mặt';
      case 'relaxation':
      case 'massage':
        return 'Thư giãn';
      case 'body':
        return 'Cơ thể';
      case 'beauty':
        return 'Thẩm mỹ';
    }

    // Legacy documents without categoryId: preserve old keyword-based behavior.
    final raw =
        '${service['category'] ?? ''} ${service['name'] ?? ''} ${service['description'] ?? ''}'
            .toLowerCase();
    if (RegExp(
      r'mi mắt|nối mi|uốn mi|phun xăm|phun môi|điêu khắc|microblading|semi.permanent',
    ).hasMatch(raw)) {
      return 'Thẩm mỹ';
    }
    if (RegExp(
      r'massage|xông hơi|gội đầu|đá nóng|foot|thư giãn|vai gáy|dưỡng sinh|sauna',
    ).hasMatch(raw)) {
      return 'Thư giãn';
    }
    if (RegExp(
      r'toàn thân|body|triệt lông|giảm béo|tắm trắng|tẩy tế bào chết toàn thân|vóc dáng',
    ).hasMatch(raw)) {
      return 'Cơ thể';
    }
    if (RegExp(
      r'da mặt|facial|peel|mụn|sẹo|nám|tàn nhang|trẻ hóa|hifu|thermage|laser|lỗ chân lông|cấy tinh chất|skincare',
    ).hasMatch(raw)) {
      return 'Da mặt';
    }
    return 'Khác';
  }

  String price(dynamic value) {
    if (value == null) return 'Liên hệ tư vấn';
    final n = num.tryParse(value.toString());
    if (n == null || n <= 0) return 'Liên hệ tư vấn';
    return '${n.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ';
  }

  Widget heading(String text, {String? detail}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            LumiAdaptive.text(text),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: LumiAdaptive.color(ink),
              ),
            ),
          ),
        ),
        if (detail != null)
          Text(
            LumiAdaptive.text(detail),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 14,
                color: LumiAdaptive.color(rose),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: LumiAdaptive.color(rose, surface: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 115),
        children: [
          // LUMI V4: Shared brand header.

          Text(
            LumiAdaptive.text('Liệu trình chăm sóc'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: LumiAdaptive.color(ink),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            LumiAdaptive.text(
              'Khám phá những liệu trình phù hợp với nhu cầu của bạn.',
            ),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 15,
                height: 1.5,
                color: LumiAdaptive.color(muted),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.asset(
                  'assets/images/welcome_spa_3.png',
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        LumiAdaptive.color(Color(0xAA35252E), surface: true),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    LumiAdaptive.text('Một khoảng lặng cho riêng mình'),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        color: LumiAdaptive.color(Colors.white),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(fontSize: 16, color: LumiAdaptive.color(ink)),
            ),
            decoration: InputDecoration(
              hintText: LumiAdaptive.optionalText('Tìm dịch vụ, liệu trình...'),
              hintStyle: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(muted),
                  fontSize: 15,
                ),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: LumiAdaptive.color(rose),
              ),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: LumiAdaptive.color(Colors.white, surface: true),
              contentPadding: const EdgeInsets.symmetric(vertical: 17),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: LumiAdaptive.color(Color(0xFFEADFD5)),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: LumiAdaptive.color(rose),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          heading('Khám phá danh mục'),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = categories[index];
                final selected = item == _category;
                return ChoiceChip(
                  label: Text(LumiAdaptive.text(item)),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = item),
                  backgroundColor: LumiAdaptive.color(
                    index.isEven ? blush : blue,
                    surface: true,
                  ),
                  selectedColor: LumiAdaptive.color(rose, surface: true),
                  showCheckmark: false,
                  labelStyle: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(selected ? Colors.white : ink),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.servicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: LumiAdaptive.color(rose),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _message(
                  'Chưa thể kết nối danh sách dịch vụ',
                  'Hãy kiểm tra máy chủ LUMI API và thử lại.',
                  retry: true,
                );
              }
              final services = snapshot.data ?? [];
              if (services.isEmpty) {
                return _message(
                  'Chưa có dịch vụ được đăng tải',
                  'Khi spa cập nhật dịch vụ lên hệ thống, danh sách sẽ xuất hiện tại đây.',
                );
              }
              final query = _search.text.trim().toLowerCase();
              final visible = services.where((service) {
                final matchesCategory =
                    _category == 'Tất cả' || categoryOf(service) == _category;
                final matchesText =
                    '${service['name'] ?? ''} ${service['description'] ?? ''}'
                        .toLowerCase()
                        .contains(query);
                return matchesCategory && matchesText;
              }).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading(
                    'Các liệu trình tại LUMI',
                    detail: '${visible.length} dịch vụ',
                  ),
                  if (visible.isEmpty)
                    _message(
                      'Không tìm thấy liệu trình phù hợp',
                      'Hãy thử từ khóa hoặc danh mục khác.',
                    ),
                  for (final service in visible) _serviceCard(service),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LumiAdaptive.color(blue, surface: true),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LumiAdaptive.text('Cần tư vấn liệu trình?'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: LumiAdaptive.color(ink),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LumiAdaptive.text(
                    'LUMI sẽ giúp bạn lựa chọn trải nghiệm phù hợp.',
                  ),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      fontSize: 15,
                      height: 1.5,
                      color: LumiAdaptive.color(muted),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            LumiAdaptive.text(
                              'Tư vấn liệu trình đang được phát triển.',
                            ),
                          ),
                        ),
                      );
                    },
                    style: LumiAdaptive.style(
                      FilledButton.styleFrom(
                        backgroundColor: LumiAdaptive.color(
                          rose,
                          surface: true,
                        ),
                        foregroundColor: LumiAdaptive.color(Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    child: Text(
                      LumiAdaptive.text('Đặt lịch tư vấn'),
                      style: LumiAdaptive.style(
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String title, String subtitle, {bool retry = false}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LumiAdaptive.color(blush, surface: true),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.spa_outlined, color: LumiAdaptive.color(rose), size: 34),
            const SizedBox(height: 12),
            Text(
              LumiAdaptive.text(title),
              textAlign: TextAlign.center,
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontSize: 17,
                  color: LumiAdaptive.color(ink),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LumiAdaptive.text(subtitle),
              textAlign: TextAlign.center,
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.5,
                  color: LumiAdaptive.color(muted),
                ),
              ),
            ),
            if (retry)
              TextButton(
                onPressed: () {
                  widget.onRefresh();
                },
                child: Text(LumiAdaptive.text('THỬ LẠI')),
              ),
          ],
        ),
      );

  Widget _serviceCard(Map<String, dynamic> service) {
    final name = (service['name'] ?? 'Dịch vụ LUMI').toString();
    final description = (service['description'] ?? '').toString();
    final minutes = service['durationMinutes'];
    final duration = minutes == null ? 'Liệu trình spa' : '$minutes phút';
    final cost = price(service['price']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(Colors.white, surface: true),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LumiAdaptive.color(const Color(0xFFEEDFE3))),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openServiceDetail(service),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 188,
              width: double.infinity,
              child: LumiCatalogImage(item: service),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LumiAdaptive.text(categoryOf(service).toUpperCase()),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        color: LumiAdaptive.color(rose),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    LumiAdaptive.text(name),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: LumiAdaptive.color(ink),
                      ),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      LumiAdaptive.text(description),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 14,
                          height: 1.5,
                          color: LumiAdaptive.color(muted),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: LumiAdaptive.color(muted),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        LumiAdaptive.text(duration),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            color: LumiAdaptive.color(muted),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        LumiAdaptive.text(cost),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            color: LumiAdaptive.color(ink),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openServiceDetail(service),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: Text(LumiAdaptive.text('Khám phá liệu trình')),
                      style: LumiAdaptive.style(
                        OutlinedButton.styleFrom(
                          foregroundColor: LumiAdaptive.color(rose),
                          side: BorderSide(color: LumiAdaptive.color(rose)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openServiceDetail(Map<String, dynamic> service) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LumiSpaServiceDetailScreen(
          service: service,
          category: categoryOf(service),
          formattedPrice: price(service['price']),
          onBook: () => widget.onBook(service),
        ),
      ),
    );
  }
}
