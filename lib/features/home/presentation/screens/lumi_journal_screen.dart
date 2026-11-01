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
  static const ink = Color(0xFF403735);
  static const rose = Color(0xFFA5553E);
  static const bg = Color(0xFFFFF8EF);
  static const blue = Color(0xFFE8F2F6);
  static const blush = Color(0xFFFBE7DC);
  final _search = TextEditingController();
  String _category = 'Tất cả';
  int _section = 0;

  List<_Story> _remoteStories = const [];
  bool _journalLoading = true;
  String? _journalError;

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
            'Góc chăm sóc da',
            style: GoogleFonts.dmSans(fontSize: 27),
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
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              story.title,
              style: GoogleFonts.dmSans(
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
                fontSize: 14,
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
              style: GoogleFonts.dmSans(color: rose, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );

  // ignore: unused_element
  // ignore: unused_element
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
                    fontSize: 14,
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
                  style: GoogleFonts.dmSans(color: rose, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _storiesPage() {
    if (_journalLoading) {
      return const Center(child: CircularProgressIndicator(color: rose));
    }

    if (_journalError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: ink),
              const SizedBox(height: 18),
              Text(
                'Chưa tải được bài viết',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _journalError!.contains('permission-denied')
                    ? 'Tài khoản chưa có quyền đọc nội dung này.'
                    : 'Vui lòng kiểm tra kết nối và thử lại.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  height: 1.5,
                  color: ink,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _loadJournal,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF5BEA5),
                  foregroundColor: ink,
                  minimumSize: const Size(140, 52),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final query = _search.text.trim().toLowerCase();
    final categories = <String>{
      'Tất cả',
      ..._remoteStories.map((story) => story.category),
    };
    final filtered = _remoteStories.where((story) {
      return (_category == 'Tất cả' || story.category == _category) &&
          (query.isEmpty ||
              '${story.title} ${story.summary} ${story.category}'
                  .toLowerCase()
                  .contains(query));
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadJournal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(fontSize: 16, color: ink),
            decoration: InputDecoration(
              hintText: 'Tìm bài viết',
              prefixIcon: const Icon(Icons.search_rounded, color: ink),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      showCheckmark: false,
                      selectedColor: const Color(0xFFF5BEA5),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      labelStyle: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                query.isEmpty
                    ? 'Chưa có bài viết.'
                    : 'Không tìm thấy bài viết phù hợp.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 17, color: ink),
              ),
            ),
          for (final story in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openStory(story),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _photo(story.image, height: 200),
                        const SizedBox(height: 16),
                        Text(
                          '${story.category} · ${story.minutes} phút đọc',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: const Color(0xFF756863),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          story.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 22,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Đọc bài viết',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_rounded, color: ink),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _shortsPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'LUMI SHORTS',
        style: GoogleFonts.dmSans(
          color: rose,
          fontSize: 14,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Little moments, big glow.',
        style: GoogleFonts.dmSans(
          fontSize: 35,
          color: ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        'Ý tưởng video ngắn cho LUMI. Chưa có MP4 thật nên không hiển thị nút phát giả.',
        style: GoogleFonts.dmSans(color: ink, fontSize: 14, height: 1.5),
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
                        fontSize: 14,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$1,
                      style: GoogleFonts.dmSans(
                        fontSize: 27,
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sắp ra mắt',
                      style: GoogleFonts.dmSans(color: rose, fontSize: 14),
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
          fontSize: 14,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        'A softer kind of beauty.',
        style: GoogleFonts.dmSans(
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
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Chăm sóc bản thân là một hành trình, không phải một đích đến.',
              style: GoogleFonts.dmSans(color: ink, fontSize: 26, height: 1.15),
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
        style: GoogleFonts.dmSans(color: rose, fontSize: 14, height: 1.5),
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
        'Góc chăm sóc da',
        style: GoogleFonts.dmSans(fontSize: 29, fontWeight: FontWeight.w700),
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
                            fontSize: 14,
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
