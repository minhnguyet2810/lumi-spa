import '../../../../core/data/lumi_journal_repository.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Journal V2.1: editorial demo content. V2.2 will replace this with an API.
class LumiJournalScreen extends StatefulWidget {
  const LumiJournalScreen({super.key});

  @override
  State<LumiJournalScreen> createState() => _LumiJournalScreenState();
}

class _Story {
  const _Story(
    this.category,
    this.title,
    this.summary,
    this.image,
    this.minutes,
    this.paragraphs,
  );
  final String category, title, summary, image;
  final int minutes;
  final List<String> paragraphs;
}

class _LumiJournalScreenState extends State<LumiJournalScreen> {
  static const ink = Color(0xFF503B42);
  static const rose = Color(0xFFB56F86);
  static const bg = Color(0xFFFFFAF9);
  static const blue = Color(0xFFDDECEF);
  static const blush = Color(0xFFF4E4E8);
  final _search = TextEditingController();
  String _category = 'Tất cả';
  int _section = 0;

  static const _demoStories = <_Story>[
    _Story(
      'Chăm sóc da',
      'Một làn da khỏe bắt đầu từ những thói quen nhỏ',
      'Chăm sóc làn da mỗi ngày theo cách nhẹ nhàng và nhất quán.',
      'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=1100&q=85',
      4,
      [
        'Một chu trình chăm sóc da không cần quá nhiều bước. Điều quan trọng là lựa chọn sản phẩm phù hợp với nhu cầu và duy trì đều đặn.',
        'Hãy bắt đầu với làm sạch dịu nhẹ, dưỡng ẩm và kem chống nắng phổ rộng vào ban ngày. Khi thử hoạt chất mới, nên đưa vào từ từ để quan sát phản ứng của da.',
        'Nếu da kích ứng kéo dài hoặc có vấn đề cần điều trị, bạn nên trao đổi với chuyên gia da liễu.',
      ],
    ),
    _Story(
      'Chăm sóc da',
      'Serum và kem dưỡng: thứ tự nào phù hợp?',
      'Hiểu vai trò của từng bước trong routine dưỡng da.',
      'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&q=85',
      3,
      [
        'Thông thường, sản phẩm có kết cấu mỏng nhẹ được sử dụng trước, sau bước làm sạch da.',
        'Serum có thể hướng đến một nhu cầu cụ thể, trong khi kem dưỡng giúp duy trì độ ẩm và hỗ trợ hàng rào bảo vệ da.',
        'Hãy ưu tiên hướng dẫn của từng sản phẩm và tránh kết hợp quá nhiều hoạt chất mạnh cùng lúc.',
      ],
    ),
    _Story(
      'Wellness',
      'Một buổi tối thật chậm dành cho bản thân',
      'Những thói quen nhỏ để kết thúc ngày dài dễ chịu hơn.',
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&q=85',
      5,
      [
        'Một khoảng thời gian thư giãn không cần quá cầu kỳ. Bạn có thể giảm ánh sáng, tạm tắt thông báo và chuẩn bị một không gian yên tĩnh.',
        'Tắm nước ấm vừa phải, dưỡng ẩm và đọc vài trang sách là những gợi ý đơn giản.',
        'Điều đáng quý nhất là tạo ra nhịp nghỉ ngơi phù hợp với chính bạn.',
      ],
    ),
    _Story(
      'Liệu trình',
      'Peel da: những điều nên tìm hiểu trước khi trải nghiệm',
      'Hiểu đúng về quy trình và các lưu ý chăm sóc da.',
      'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=900&q=85',
      5,
      [
        'Peel da sử dụng các hoạt chất để tác động lên bề mặt da. Hiệu quả và mức độ phù hợp phụ thuộc vào tình trạng da, hoạt chất và quy trình thực hiện.',
        'Bạn nên được tư vấn chuyên môn trước khi lựa chọn liệu trình, đặc biệt khi da đang nhạy cảm hoặc đang dùng thuốc điều trị.',
        'Chăm sóc và chống nắng sau liệu trình cần tuân theo hướng dẫn của người thực hiện.',
      ],
    ),
    _Story(
      'Wellness',
      'Vì sao một buổi massage có thể giúp bạn thư giãn?',
      'Khám phá một cách dành thời gian chăm sóc cơ thể.',
      'https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=900&q=85',
      4,
      [
        'Massage thường được lựa chọn như một trải nghiệm thư giãn và chăm sóc cơ thể.',
        'Không gian yên tĩnh, nhịp độ nhẹ nhàng và cảm giác được chăm sóc có thể giúp bạn dễ chịu hơn sau ngày dài.',
        'Nếu có bệnh lý, chấn thương hoặc đang mang thai, hãy hỏi ý kiến chuyên môn về loại massage phù hợp.',
      ],
    ),
    _Story(
      'LUMI',
      'Một chút dịu dàng trong triết lý LUMI',
      'Khám phá tinh thần thiết kế của dự án LUMI SPA.',
      'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=900&q=85',
      3,
      [
        'LUMI được xây dựng như một trải nghiệm số dành cho chăm sóc bản thân, với bảng màu ivory, dusty rose và những khoảng trắng nhẹ nhàng.',
        'Từ việc khám phá dịch vụ đến tìm hiểu sản phẩm, mục tiêu thiết kế là tạo ra một hành trình dễ sử dụng và gần gũi.',
        'Đây là nội dung giới thiệu ý tưởng của dự án, không phải tuyên bố về một cơ sở spa đã được xác minh.',
      ],
    ),
  ];

  List<_Story> _remoteStories = const [];
  bool _journalLoading = true;
  String? _journalError;
  List<_Story> get _stories =>
      _remoteStories.isEmpty ? _demoStories : _remoteStories;
  bool get _isDemo => _remoteStories.isEmpty;

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  Future<void> _loadJournal() async {
    if (mounted) {
      setState(() {
        _journalLoading = true;
        _journalError = null;
      });
    }
    try {
      final records = await LumiJournalRepository.fetchArticles();
      final stories = <_Story>[];
      for (final record in records) {
        String field(String key) => (record[key] ?? '').toString().trim();
        final title = field('title');
        if (title.isEmpty) {
          continue;
        }
        final raw = record['paragraphs'];
        final paragraphs = raw is List
            ? raw
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : field('content')
                  .split(RegExp(r'\n\s*\n'))
                  .where((e) => e.trim().isNotEmpty)
                  .toList();
        final image = field('imageUrl').isNotEmpty
            ? field('imageUrl')
            : field('coverImageUrl');
        final minutes = record['readMinutes'];
        stories.add(
          _Story(
            field('category').isEmpty ? 'LUMI' : field('category'),
            title,
            field('summary'),
            image,
            minutes is num && minutes > 0 ? minutes.toInt() : 3,
            paragraphs,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteStories = stories;
        _journalLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _journalError = e.toString();
        _journalLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _photo(
    String url, {
    double? height,
    double? width,
    BorderRadius? radius,
  }) => ClipRRect(
    borderRadius: radius ?? BorderRadius.circular(18),
    child: SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: blush,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: rose,
                ),
              ),
        errorBuilder: (_, _, _) => Container(
          color: blush,
          alignment: Alignment.center,
          child: const Icon(Icons.spa_outlined, size: 32, color: rose),
        ),
      ),
    ),
  );

  void _openStory(_Story story) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          foregroundColor: ink,
          title: Text(
            'LUMI Journal',
            style: GoogleFonts.cormorantGaramond(fontSize: 27),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 35),
          children: [
            _photo(story.image, height: 245),
            const SizedBox(height: 24),
            Text(
              story.category.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: rose,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              story.title,
              style: GoogleFonts.cormorantGaramond(
                color: ink,
                fontSize: 39,
                height: 1.04,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'LUMI EDITORIAL  ·  ${story.minutes} PHÚT ĐỌC',
              style: GoogleFonts.dmSans(
                color: rose,
                fontSize: 11,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 19),
            Text(
              story.summary,
              style: GoogleFonts.dmSans(
                color: ink,
                fontSize: 17,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final paragraph in story.paragraphs)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  paragraph,
                  style: GoogleFonts.dmSans(
                    color: ink,
                    fontSize: 15,
                    height: 1.75,
                  ),
                ),
              ),
            const SizedBox(height: 26),
            Text(
              'Bài viết mẫu cho dự án LUMI SPA · Nội dung mang tính tham khảo.',
              style: GoogleFonts.dmSans(color: rose, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _storyRow(_Story story) => InkWell(
    onTap: () => _openStory(story),
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photo(story.image, width: 116, height: 112),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${story.category.toUpperCase()}  ·  ${story.minutes} PHÚT',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: rose,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  story.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    height: 1.35,
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Đọc bài viết  ↗',
                  style: GoogleFonts.dmSans(color: rose, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _storiesPage() {
    final query = _search.text.trim().toLowerCase();
    final filtered = _stories
        .where(
          (s) =>
              (_category == 'Tất cả' || s.category == _category) &&
              (query.isEmpty ||
                  '${s.title} ${s.summary} ${s.category}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
      children: [
        if (_journalLoading)
          const LinearProgressIndicator(color: rose, minHeight: 2),
        if (_journalError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Firebase error: ${_journalError ?? "unknown"}',
                    style: const TextStyle(color: rose, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _loadJournal,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        if (!_journalLoading && _journalError == null && _isDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'BÀI VIẾT MẪU · Chưa có bài đã xuất bản trên Firestore',
              style: GoogleFonts.dmSans(color: rose, fontSize: 11),
            ),
          ),
        Text(
          'THE LUMI EDIT',
          style: GoogleFonts.dmSans(
            color: rose,
            fontSize: 11,
            letterSpacing: 2.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Journal.',
          style: GoogleFonts.cormorantGaramond(
            color: ink,
            fontSize: 49,
            height: 1,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Your daily dose of beauty & calm.',
          style: GoogleFonts.dmSans(
            color: ink.withValues(alpha: .75),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 19),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: rose),
            hintText: 'Tìm bài viết, chủ đề...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: blush),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: blush),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in const [
                'Tất cả',
                'Chăm sóc da',
                'Wellness',
                'Liệu trình',
                'LUMI',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    selectedColor: blush,
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.dmSans(color: ink, fontSize: 12),
                    side: const BorderSide(color: blush),
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 21),
        if (_category == 'Tất cả' && query.isEmpty) ...[
          InkWell(
            onTap: () => _openStory(_stories.first),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _photo(_stories.first.image, height: 210),
                const SizedBox(height: 12),
                Text(
                  "EDITOR'S PICK · SKINCARE",
                  style: GoogleFonts.dmSans(
                    color: rose,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _stories.first.title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 30,
                    height: 1.08,
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _stories.first.summary,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: ink,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'Latest Stories',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 29,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: 5),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Chưa có bài viết phù hợp.',
              style: GoogleFonts.dmSans(color: ink),
            ),
          ),
        for (final story in filtered) _storyRow(story),
        const SizedBox(height: 15),
        Text(
          _isDemo
              ? 'Nội dung mẫu để xem trước · Firestore chưa có bài xuất bản.'
              : 'Bài viết được tải từ LUMI Firestore.',
          style: GoogleFonts.dmSans(color: rose, fontSize: 11),
        ),
      ],
    );
  }

  Widget _shortsPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'LUMI SHORTS',
        style: GoogleFonts.dmSans(
          color: rose,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Little moments, big glow.',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 35,
          color: ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        'Ý tưởng video ngắn cho LUMI. Chưa có MP4 thật nên không hiển thị nút phát giả.',
        style: GoogleFonts.dmSans(color: ink, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 18),
      for (final item in const [
        (
          '60 giây thư giãn',
          'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&q=85',
        ),
        (
          'Skincare buổi tối',
          'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&q=85',
        ),
        (
          'Một ngày tại LUMI',
          'https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=900&q=85',
        ),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: [
              _photo(item.$2, width: 132, height: 176),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIDEO CONCEPT',
                      style: GoogleFonts.dmSans(
                        color: rose,
                        fontSize: 10,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$1,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 27,
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sắp ra mắt',
                      style: GoogleFonts.dmSans(color: rose, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _aboutPage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
    children: [
      _photo(
        'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=1100&q=85',
        height: 230,
      ),
      const SizedBox(height: 23),
      Text(
        'DISCOVER LUMI',
        style: GoogleFonts.dmSans(
          color: rose,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        'A softer kind of beauty.',
        style: GoogleFonts.cormorantGaramond(
          color: ink,
          fontSize: 39,
          height: 1.04,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 17),
      Text(
        'LUMI SPA & WELLNESS là dự án ứng dụng chăm sóc sắc đẹp được thiết kế với tinh thần nhẹ nhàng, thanh lịch và đặt trải nghiệm cá nhân làm trung tâm.',
        style: GoogleFonts.dmSans(color: ink, fontSize: 15, height: 1.75),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: blue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OUR PHILOSOPHY',
              style: GoogleFonts.dmSans(
                color: rose,
                letterSpacing: 1.6,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Chăm sóc bản thân là một hành trình, không phải một đích đến.',
              style: GoogleFonts.cormorantGaramond(
                color: ink,
                fontSize: 26,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Trong ứng dụng, bạn có thể tìm hiểu liệu trình, khám phá mỹ phẩm và lên kế hoạch cho những phút giây thư giãn.',
        style: GoogleFonts.dmSans(color: ink, fontSize: 15, height: 1.75),
      ),
      const SizedBox(height: 22),
      Text(
        'Giới thiệu ý tưởng thương hiệu mẫu của dự án; chưa phải thông tin xác minh về một cơ sở kinh doanh.',
        style: GoogleFonts.dmSans(color: rose, fontSize: 12, height: 1.5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      title: Text(
        'LUMI Journal',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 29,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              for (final (index, label) in [
                (0, 'Bài viết'),
                (1, 'Shorts'),
                (2, 'Về LUMI'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _section = index),
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _section == index ? blush : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: ink,
                            fontSize: 12,
                            fontWeight: _section == index
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _section,
            children: [_storiesPage(), _shortsPage(), _aboutPage()],
          ),
        ),
      ],
    ),
  );
}
