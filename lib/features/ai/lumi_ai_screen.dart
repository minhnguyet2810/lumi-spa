import 'package:lumi_spa/core/network/api_config.dart';
import 'package:lumi_spa/features/home/presentation/screens/lumi_booking_screen.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumi_spa/core/network/lumi_api_client.dart';
import 'package:lumi_spa/core/settings/app_preferences.dart';
import 'package:lumi_spa/core/widgets/lumi_catalog_image.dart';

class LumiAiScreen extends StatefulWidget {
  const LumiAiScreen({super.key});
  @override
  State<LumiAiScreen> createState() => _LumiAiScreenState();
}

class _LumiAiScreenState extends State<LumiAiScreen> {
  final _message = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  StreamSubscription<User?>? _auth;
  String? _uid;
  Uint8List? _photo;
  String? _mime, _error;
  bool _busy = false, _images = false, _configured = false, _accepted = false;
  int _epoch = 0;
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _status();
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) {
        return;
      }
      setState(() {
        _epoch++;
        _uid = user?.uid;
        _messages.clear();
        _photo = null;
        _error = null;
        _accepted = false;
        _busy = false;
        _configured = false;
        _images = false;
        _message.clear();
      });
      _status();
    });
  }

  Future<void> _status() async {
    final epoch = _epoch;
    try {
      final response = await LumiApiClient.instance.get('/api/ai/status');
      if (mounted && epoch == _epoch) {
        setState(() {
          _images = response['data']['imagesEnabled'] == true;
          _configured = response['data']['configured'] == true;
          _error = _configured
              ? null
              : context.lumiText(
                  'Backend chưa đọc được khóa Gemini. Kiểm tra cấu hình và khởi động lại backend.',
                  'The backend has no Gemini key. Check its configuration and restart it.',
                );
        });
      }
    } catch (error) {
      if (mounted && epoch == _epoch) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  void dispose() {
    _auth?.cancel();
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final epoch = _epoch;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      if (file == null) {
        return;
      }
      if (await file.length() > 1572864) {
        throw Exception('Chọn ảnh dưới 1,5 MB / Choose an image under 1.5 MB.');
      }
      final bytes = await file.readAsBytes();
      final jpeg =
          bytes.length > 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      final png =
          bytes.length > 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      if (!jpeg && !png) {
        throw Exception('Chọn JPEG hoặc PNG / Choose JPEG or PNG.');
      }
      if (mounted && epoch == _epoch) {
        setState(() {
          _photo = bytes;
          _mime = jpeg ? 'image/jpeg' : 'image/png';
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && epoch == _epoch) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<bool> _consent(bool image) async {
    if (_accepted && !image) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              ctx.lumiText(
                'Trước khi gửi đến Gemini',
                'Before sending to Gemini',
              ),
            ),
            content: SingleChildScrollView(
              child: Text(
                ctx.lumiText(
                  'Dành cho người từ 18 tuổi. Nội dung chat${image ? ' và ảnh đã chọn' : ''} được gửi qua máy chủ LUMI tới Google Gemini. LUMI không lưu hội thoại hoặc ảnh vào cơ sở dữ liệu trong tính năng này. Google xử lý dữ liệu theo điều khoản dịch vụ; hạn mức miễn phí có thể dùng nội dung để cải thiện sản phẩm. Không gửi thông tin riêng tư hoặc nhạy cảm.\n\nAI chỉ hỗ trợ mua sắm mỹ phẩm và nhận xét bề ngoài, không chẩn đoán hoặc điều trị. Bạn đồng ý gửi nội dung này?',
                  'For adults 18+. Your message${image ? ' and selected photo' : ''} will be sent through LUMI to Google Gemini. This feature does not save chat or photos to LUMI databases. Google processes data under its terms; unpaid quota may use content to improve products. Do not send private or sensitive information.\n\nAI offers cosmetic shopping help and appearance feedback, not diagnosis or treatment. Do you agree?',
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.lumiText('Hủy', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  ctx.lumiText(
                    'Tôi đủ 18 tuổi và đồng ý',
                    'I am 18+ and agree',
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _send() async {
    if (_busy) {
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      setState(
        () => _error = context.lumiText(
          'Bạn có thể soạn tin nhắn. Để gửi, hãy quay lại Tài khoản và đăng nhập.',
          'You can draft a message. To send, return to Account and sign in.',
        ),
      );
      return;
    }
    final draft = _message.text.trim();
    final text = draft.isEmpty && _photo != null
        ? context.lumiText(
            'Hãy nhận xét bề ngoài trong ảnh một cách thận trọng, hỏi thêm về nhu cầu của tôi rồi gợi ý mỹ phẩm hoặc dịch vụ LUMI phù hợp nếu đủ thông tin.',
            'Please give cautious cosmetic appearance feedback, ask about my needs, and suggest LUMI products or services only if there is enough information.',
          )
        : draft;
    if (text.isEmpty) {
      return;
    }
    if (text.length > 2000) {
      setState(
        () => _error = context.lumiText(
          'Tối đa 2.000 ký tự.',
          'Maximum 2,000 characters.',
        ),
      );
      return;
    }
    final epoch = _epoch;
    final image = _photo, mime = _mime;
    setState(() => _busy = true);
    try {
      if (!await _consent(image != null)) {
        return;
      }
      if (!mounted || epoch != _epoch) {
        return;
      }
      _accepted = true;
      final history = _messages
          .map(
            (m) => {
              'role': m['role'],
              'text': (m['text'] as String).substring(
                0,
                (m['text'] as String).length.clamp(0, 2000).toInt(),
              ),
            },
          )
          .toList();
      final response = await LumiApiClient.instance.post(
        '/api/ai/chat',
        body: {
          'message': text,
          'ageConfirmed': true,
          'history': history.length > 12
              ? history.sublist(history.length - 12)
              : history,
          if (image != null) 'imageConsent': true,
          if (image != null)
            'image': {'mimeType': mime, 'data': base64Encode(image)},
        },
      );
      if (!mounted || epoch != _epoch) {
        return;
      }
      final data = Map<String, dynamic>.from(response['data'] as Map);
      setState(() {
        _messages.add({
          'role': 'user',
          'text': text,
          'hadImage': image != null,
        });
        _messages.add({
          'role': 'assistant',
          'text': data['reply'],
          'products': data['recommendations'],
        });
        _photo = null;
        _mime = null;
        if (_message.text.trim() == text) {
          _message.clear();
        }
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (error) {
      if (mounted && epoch == _epoch) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() => _busy = false);
      }
    }
  }

  void _product(Map raw) {
    final item = Map<String, dynamic>.from(raw);
    if (item['type'] == 'service') {
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => LumiBookingScreen(service: item)),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LumiCatalogImage(item: item, height: 180),
              const SizedBox(height: 16),
              Text(
                item['name'].toString(),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              Text('${item['price']} đ'),
              const SizedBox(height: 12),
              Text(item['description']?.toString() ?? ''),
              const SizedBox(height: 12),
              Text(
                ctx.lumiText(
                  'Bạn có thể tìm sản phẩm này trong Cửa hàng LUMI để đặt mua.',
                  'Find this product in the LUMI Shop to purchase.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lumiText('LUMI AI', 'LUMI AI')),
        actions: [
          IconButton(
            tooltip: context.lumiText('Xóa hội thoại', 'Clear conversation'),
            onPressed: _busy
                ? null
                : () => setState(() {
                    _messages.clear();
                    _photo = null;
                    _error = null;
                  }),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                context.lumiText(
                  'Hỏi về routine, nhu cầu và ngân sách. AI có thể sai; nhận xét ảnh không phải chẩn đoán.',
                  'Ask about your routine, needs and budget. AI can make mistakes; photo feedback is not a diagnosis.',
                ),
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_messages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        context.lumiText(
                          'Ví dụ: Tôi muốn routine đơn giản, da thường bóng vào buổi chiều, ngân sách 500.000đ. Tôi cần cho bạn biết gì thêm?',
                          'Example: I want a simple routine. My skin looks shiny in the afternoon and my budget is 500,000 VND. What else should I tell you?',
                        ),
                      ),
                    ),
                  for (final m in _messages)
                    Align(
                      alignment: m['role'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        constraints: const BoxConstraints(maxWidth: 650),
                        decoration: BoxDecoration(
                          color: m['role'] == 'user'
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m['hadImage'] == true)
                              Text(
                                context.lumiText(
                                  'Đã gửi kèm ảnh',
                                  'Photo attached',
                                ),
                              ),
                            SelectableText(
                              m['text'].toString(),
                              style: TextStyle(
                                color: m['role'] == 'user'
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                              ),
                            ),
                            for (final p
                                in (m['products'] as List? ?? [])
                                    .whereType<Map>())
                              Card(
                                child: ListTile(
                                  title: Text(p['name'].toString()),
                                  subtitle: Text(
                                    '${p['price']} đ · ${p['type'] == 'service' ? context.lumiText('Xem và đặt lịch', 'View and book') : context.lumiText('Sản phẩm', 'Product')}',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => _product(p),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: TextStyle(color: colors.error)),
              ),
            if (_error != null)
              ExpansionTile(
                title: Text(
                  context.lumiText('Chi tiết kết nối', 'Connection details'),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      '${ApiConfig.baseUrl} · /api/ai/status',
                    ),
                  ),
                ],
              ),
            if (!_configured)
              TextButton(
                onPressed: _busy ? null : _status,
                child: Text(
                  context.lumiText(
                    'Kiểm tra kết nối AI',
                    'Check AI connection',
                  ),
                ),
              ),
            if (_photo != null)
              SizedBox(
                height: 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.memory(
                      _photo!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _photo = null),
                      tooltip: context.lumiText('Bỏ ảnh', 'Remove photo'),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            if (!_images)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  context.lumiText(
                    'Ảnh chưa được bật. Bạn có thể chat bằng văn bản.',
                    'Photo feedback is not enabled. Text chat is available.',
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<ImageSource>(
                    enabled: !_busy && _images && _uid != null,
                    tooltip: context.lumiText('Thêm ảnh', 'Add photo'),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    onSelected: _pick,
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: ImageSource.camera,
                        child: Text(ctx.lumiText('Chụp ảnh', 'Camera')),
                      ),
                      PopupMenuItem(
                        value: ImageSource.gallery,
                        child: Text(ctx.lumiText('Chọn ảnh', 'Gallery')),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TextField(
                      controller: _message,
                      enabled: true,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: context.lumiText('Nhắn LUMI…', 'Ask LUMI…'),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : _send,
                    tooltip: context.lumiText('Gửi', 'Send'),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
