import '../../../../core/theme/lumi_adaptive.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lumi_journal_media.dart';

class LumiAboutPage extends StatefulWidget {
  const LumiAboutPage({super.key});
  @override
  State<LumiAboutPage> createState() => _LumiAboutPageState();
}

class _LumiAboutPageState extends State<LumiAboutPage> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _stream;
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _stream = FirebaseFirestore.instance
        .collection('app_config')
        .doc('about_lumi')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final en = Localizations.localeOf(context).languageCode == 'en';
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 38),
                    const SizedBox(height: 16),
                    Text(
                      LumiAdaptive.text(
                        en
                            ? 'Could not load our story.'
                            : 'Chưa tải được giới thiệu LUMI.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(_connect),
                      child: Text(LumiAdaptive.text(en ? 'Retry' : 'Thử lại')),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data();
          if (data == null) {
            return Center(
              child: Text(
                LumiAdaptive.text(
                  en
                      ? 'Our story will be available soon.'
                      : 'LUMI chưa cập nhật nội dung giới thiệu.',
                ),
              ),
            );
          }
          String field(String key) {
            final translated = data[en ? '${key}En' : key];
            return (translated ?? data[key] ?? '').toString().trim();
          }

          final raw = data[en ? 'sectionsEn' : 'sections'] ?? data['sections'];
          final sections = raw is List
              ? raw.whereType<Map>().toList()
              : <Map>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SizedBox(
                  height: 230,
                  child: LumiJournalMotionPhoto(url: field('imageUrl')),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                LumiAdaptive.text(en ? 'OUR STORY' : 'CÂU CHUYỆN LUMI'),
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                LumiAdaptive.text(field('title')),
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 32,
                    height: 1.2,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LumiAdaptive.text(field('intro')),
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 17,
                    height: 1.7,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (field('quote').isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: colors.onSecondaryContainer,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LumiAdaptive.text(field('quote')),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontSize: 23,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              for (var i = 0; i < sections.length; i++) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LumiAdaptive.text((i + 1).toString().padLeft(2, '0')),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LumiAdaptive.text(
                          (sections[i]['title'] ?? '').toString(),
                        ),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontSize: 22,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LumiAdaptive.text(
                          (sections[i]['body'] ?? '').toString(),
                        ),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontSize: 17,
                            height: 1.7,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Text(
                LumiAdaptive.text(
                  en ? 'Thank you for making LUMI part of your day.' : 'Cảm ơn bạn đã để LUMI trở thành một phần trong hành trình chăm sóc bản thân.',
                ),
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 18,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
