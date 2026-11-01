import '../../../../core/theme/lumi_adaptive.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

const _ink = Color(0xFF403735);
const _accent = Color(0xFFA5553E);
const _cream = Color(0xFFFFF8EF);

/// Uses the same published articles query as the existing repository.
class LumiJournalFeature extends StatefulWidget {
  const LumiJournalFeature({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  State<LumiJournalFeature> createState() => _LumiJournalFeatureState();
}

class _LumiJournalFeatureState extends State<LumiJournalFeature> {
  late final _stream = FirebaseFirestore.instance
      .collection('articles')
      .where('isPublished', isEqualTo: true)
      .snapshots();
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _stream,
    builder: (context, snapshot) {
      final docs = [...?snapshot.data?.docs];
      docs.sort((a, b) {
        int date(Map<String, dynamic> data) {
          final value = data['publishedAt'];
          if (value is Timestamp) {
            return value.millisecondsSinceEpoch;
          }
          if (value is String) {
            return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
          }
          return 0;
        }

        return date(b.data()).compareTo(date(a.data()));
      });
      Map<String, dynamic>? article;
      for (final doc in docs) {
        final data = doc.data();
        if ((data['title'] ?? '').toString().trim().isNotEmpty) {
          article = data;
          break;
        }
      }
      final image = (article?['imageUrl'] ?? '').toString().trim();
      final cover = image.isNotEmpty
          ? image
          : (article?['coverImageUrl'] ?? '').toString().trim();
      final title = (article?['title'] ?? '').toString().trim();
      return Material(
        color: LumiAdaptive.color(const Color(0xFFFBE7DC), surface: true),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 205,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LumiJournalMotionPhoto(url: cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            LumiAdaptive.color(
                              Color(0x70403735),
                              surface: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: LumiAdaptive.color(_cream, surface: true),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          LumiAdaptive.text('LUMI Journal'),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(_ink),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LumiAdaptive.text('Góc chăm sóc da'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          color: LumiAdaptive.color(_ink),
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LumiAdaptive.text(
                        title.isEmpty
                            ? 'Dành một chút thời gian để hiểu làn da của bạn.'
                            : title,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          color: LumiAdaptive.color(_ink),
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            LumiAdaptive.text('Khám phá góc chăm sóc'),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                color: LumiAdaptive.color(_accent),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          backgroundColor: LumiAdaptive.color(
                            _accent,
                            surface: true,
                          ),
                          foregroundColor: LumiAdaptive.color(Colors.white),
                          child: Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class LumiJournalMotionPhoto extends StatefulWidget {
  const LumiJournalMotionPhoto({super.key, required this.url});
  final String url;
  @override
  State<LumiJournalMotionPhoto> createState() => _LumiJournalMotionPhotoState();
}

class _LumiJournalMotionPhotoState extends State<LumiJournalMotionPhoto>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    if (!mounted) {
      return;
    }
    if (_foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_motion.isAnimating) {
        _motion.repeat(reverse: true);
      }
    } else {
      _motion.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => ClipRect(
      child: AnimatedBuilder(
        animation: _motion,
        child: widget.url.isEmpty
            ? _placeholder()
            : Image.network(
                widget.url,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, error, stack) => _placeholder(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _placeholder(),
              ),
        builder: (context, child) => Transform.scale(
          scale: MediaQuery.disableAnimationsOf(context)
              ? 1
              : 1 + _motion.value * 0.06,
          child: child,
        ),
      ),
    ),
  );
  Widget _placeholder() => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          LumiAdaptive.color(Color(0xFFF8D5C2), surface: true),
          LumiAdaptive.color(Color(0xFFE8F2F6), surface: true),
        ],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.spa_outlined,
        color: LumiAdaptive.color(_accent),
        size: 48,
      ),
    ),
  );
}

/// Optional videoUrl/thumbnailUrl fields on existing published article documents.
class LumiJournalShorts extends StatefulWidget {
  const LumiJournalShorts({super.key});
  @override
  State<LumiJournalShorts> createState() => _LumiJournalShortsState();
}

class _LumiJournalShortsState extends State<LumiJournalShorts> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _stream = FirebaseFirestore.instance
        .collection('articles')
        .where('isPublished', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LumiAdaptive.text('Chưa tải được video.')),
              TextButton(
                onPressed: () => setState(_connect),
                child: Text(LumiAdaptive.text('Thử lại')),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return Center(
          child: CircularProgressIndicator(color: LumiAdaptive.color(_accent)),
        );
      }
      final videos = snapshot.data!.docs.where((doc) {
        final uri = Uri.tryParse(
          (doc.data()['videoUrl'] ?? '').toString().trim(),
        );
        return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
      }).toList()..sort((a, b) => a.id.compareTo(b.id));
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            LumiAdaptive.text('Một chút cảm hứng mỗi ngày'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 27,
                height: 1.25,
                color: LumiAdaptive.color(_ink),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LumiAdaptive.text('Những thước phim chăm sóc và thư giãn từ LUMI.'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 16,
                height: 1.5,
                color: LumiAdaptive.color(_ink),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (videos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                LumiAdaptive.text(
                  'LUMI chưa đăng video. Bạn có thể khám phá các bài viết ở tab Bài viết.',
                ),
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 17,
                    height: 1.5,
                    color: LumiAdaptive.color(_ink),
                  ),
                ),
              ),
            ),
          for (final doc in videos)
            Builder(
              builder: (context) {
                final data = doc.data();
                final title = (data['title'] ?? 'Video LUMI').toString();
                final thumbnail =
                    (data['thumbnailUrl'] ??
                            data['imageUrl'] ??
                            data['coverImageUrl'] ??
                            '')
                        .toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Material(
                    color: LumiAdaptive.color(Colors.white, surface: true),
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _LumiVideoScreen(
                            url: data['videoUrl'].toString().trim(),
                            title: title,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 220,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                LumiJournalMotionPhoto(url: thumbnail),
                                Center(
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: LumiAdaptive.color(
                                      _cream,
                                      surface: true,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: LumiAdaptive.color(_accent),
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              LumiAdaptive.text(title),
                              style: LumiAdaptive.style(
                                GoogleFonts.dmSans(
                                  fontSize: 21,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                  color: LumiAdaptive.color(_ink),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      );
    },
  );
}

class _LumiVideoScreen extends StatefulWidget {
  const _LumiVideoScreen({required this.url, required this.title});
  final String url, title;
  @override
  State<_LumiVideoScreen> createState() => _LumiVideoScreenState();
}

class _LumiVideoScreenState extends State<_LumiVideoScreen>
    with WidgetsBindingObserver {
  late final VideoPlayerController _player;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _player.addListener(_changed);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _player.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không tải được video. Vui lòng kiểm tra kết nối hoặc thử lại sau.',
        );
      }
    }
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _player.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.removeListener(_changed);
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_player.value.isPlaying) {
        await _player.pause();
      } else {
        if (_player.value.position >= _player.value.duration) {
          await _player.seekTo(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không phát được video này.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    final value = _player.value;
    return Scaffold(
      backgroundColor: LumiAdaptive.color(_cream, surface: true),
      appBar: AppBar(
        backgroundColor: LumiAdaptive.color(_cream, surface: true),
        foregroundColor: LumiAdaptive.color(_ink),
        title: Text(LumiAdaptive.text(widget.title)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null || value.hasError)
                  Text(
                    LumiAdaptive.text(
                      _error ?? 'Video không khả dụng. Vui lòng thử lại sau.',
                    ),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontSize: 17,
                        color: LumiAdaptive.color(_ink),
                      ),
                    ),
                  )
                else if (!value.isInitialized)
                  CircularProgressIndicator(color: LumiAdaptive.color(_accent))
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: value.aspectRatio > 0
                          ? value.aspectRatio
                          : 16 / 9,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_player),
                          if (value.isBuffering)
                            CircularProgressIndicator(
                              color: LumiAdaptive.color(Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  VideoProgressIndicator(
                    _player,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: _accent,
                      bufferedColor: LumiAdaptive.color(
                        Color(0xFFF5BEA5),
                        surface: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _toggle,
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          LumiAdaptive.text(
                            value.isPlaying ? 'Tạm dừng' : 'Phát video',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: LumiAdaptive.optionalText(
                          value.volume == 0 ? 'Bật âm thanh' : 'Tắt âm thanh',
                        ),
                        onPressed: () =>
                            _player.setVolume(value.volume == 0 ? 1 : 0),
                        icon: Icon(
                          value.volume == 0
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
