import '../../../../core/theme/lumi_adaptive.dart';
import 'lumi_about_page.dart';
import 'lumi_journal_media.dart';
import '../../../../core/data/lumi_journal_repository.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Published journal content from Firestore.
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
                color: LumiAdaptive.color(blush, surface: true),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LumiAdaptive.color(rose),
                ),
              ),
        errorBuilder: (_, _, _) => Container(
          color: LumiAdaptive.color(blush),
          alignment: Alignment.center,
          child: Icon(
            Icons.spa_outlined,
            size: 32,
            color: LumiAdaptive.color(rose),
          ),
        ),
      ),
    ),
  );

  void _openStory(_Story story) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: LumiAdaptive.color(bg, surface: true),
        appBar: AppBar(
          backgroundColor: LumiAdaptive.color(bg, surface: true),
          foregroundColor: LumiAdaptive.color(ink),
          title: Text(
            LumiAdaptive.text('Góc chăm sóc da'),
            style: LumiAdaptive.style(GoogleFonts.dmSans(fontSize: 27)),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 35),
          children: [
            _photo(story.image, height: 245),
            const SizedBox(height: 24),
            Text(
              LumiAdaptive.text(story.category.toUpperCase()),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(rose),
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              LumiAdaptive.text(story.title),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(ink),
                  fontSize: 39,
                  height: 1.04,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              LumiAdaptive.text('LUMI EDITORIAL  ·  ${story.minutes} PHÚT ĐỌC'),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(rose),
                  fontSize: 14,
                  letterSpacing: .7,
                ),
              ),
            ),
            const SizedBox(height: 19),
            Text(
              LumiAdaptive.text(story.summary),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(ink),
                  fontSize: 17,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final paragraph in story.paragraphs)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  LumiAdaptive.text(paragraph),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 15,
                      height: 1.75,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 26),
            Text(
              LumiAdaptive.text(
                'Bài viết mẫu cho dự án LUMI SPA · Nội dung mang tính tham khảo.',
              ),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(rose),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _storiesPage() {
    if (_journalLoading) {
      return Center(
        child: CircularProgressIndicator(color: LumiAdaptive.color(rose)),
      );
    }

    if (_journalError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: LumiAdaptive.color(ink),
              ),
              const SizedBox(height: 18),
              Text(
                LumiAdaptive.text('Chưa tải được bài viết'),
                textAlign: TextAlign.center,
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: LumiAdaptive.color(ink),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                LumiAdaptive.text(
                  _journalError!.contains('permission-denied')
                      ? 'Tài khoản chưa có quyền đọc nội dung này.'
                      : 'Vui lòng kiểm tra kết nối và thử lại.',
                ),
                textAlign: TextAlign.center,
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 16,
                    height: 1.5,
                    color: LumiAdaptive.color(ink),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _loadJournal,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(LumiAdaptive.text('Thử lại')),
                style: LumiAdaptive.style(
                  FilledButton.styleFrom(
                    backgroundColor: LumiAdaptive.color(
                      const Color(0xFFF5BEA5),
                      surface: true,
                    ),
                    foregroundColor: LumiAdaptive.color(ink),
                    minimumSize: const Size(140, 52),
                  ),
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
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(fontSize: 16, color: LumiAdaptive.color(ink)),
            ),
            decoration: InputDecoration(
              hintText: LumiAdaptive.optionalText('Tìm bài viết'),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: LumiAdaptive.color(ink),
              ),
              filled: true,
              fillColor: LumiAdaptive.color(Colors.white, surface: true),
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
                      label: Text(LumiAdaptive.text(category)),
                      selected: _category == category,
                      showCheckmark: false,
                      selectedColor: LumiAdaptive.color(
                        const Color(0xFFF5BEA5),
                        surface: true,
                      ),
                      backgroundColor: LumiAdaptive.color(
                        Colors.white,
                        surface: true,
                      ),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      labelStyle: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: LumiAdaptive.color(ink),
                        ),
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
                LumiAdaptive.text(
                  query.isEmpty
                      ? 'Chưa có bài viết.'
                      : 'Không tìm thấy bài viết phù hợp.',
                ),
                textAlign: TextAlign.center,
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 17,
                    color: LumiAdaptive.color(ink),
                  ),
                ),
              ),
            ),
          for (final story in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: LumiAdaptive.color(Colors.white, surface: true),
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
                          LumiAdaptive.text(
                            '${story.category} · ${story.minutes} phút đọc',
                          ),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 14,
                              color: LumiAdaptive.color(
                                const Color(0xFF756863),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LumiAdaptive.text(story.title),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 22,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: LumiAdaptive.color(ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              LumiAdaptive.text('Đọc bài viết'),
                              style: LumiAdaptive.style(
                                GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: LumiAdaptive.color(ink),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: LumiAdaptive.color(ink),
                            ),
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

  Widget _shortsPage() => const LumiJournalShorts();

  Widget _aboutPage() => const LumiAboutPage();

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      backgroundColor: LumiAdaptive.color(bg, surface: true),
      appBar: AppBar(
        backgroundColor: LumiAdaptive.color(bg, surface: true),
        foregroundColor: LumiAdaptive.color(ink),
        elevation: 0,
        title: Text(
          LumiAdaptive.text('Góc chăm sóc da'),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(fontSize: 29, fontWeight: FontWeight.w700),
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
                            color: LumiAdaptive.color(
                              _section == index ? blush : Colors.white,
                              surface: true,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            LumiAdaptive.text(label),
                            textAlign: TextAlign.center,
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                color: LumiAdaptive.color(ink),
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
    ),
  );
}
