import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lumi_spa/core/network/lumi_api_client.dart';
import 'package:lumi_spa/core/settings/app_preferences.dart';
import 'package:lumi_spa/features/home/presentation/screens/lumi_booking_screen.dart';

const experiencePath = '/api/experience';
Future<void> rebookLumi(BuildContext context, String bookingId) async {
  try {
    final response = await LumiApiClient.instance.get(
      '$experiencePath/rebook/${Uri.encodeComponent(bookingId)}',
    );
    if (!context.mounted) {
      return;
    }
    final service = Map<String, dynamic>.from(response['data'] as Map);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LumiBookingScreen(service: service)),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

Future<void> reviewLumi(BuildContext context, Map<String, dynamic> row) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _ReviewDialog(row: row),
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.row});
  final Map<String, dynamic> row;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await LumiApiClient.instance.post(
        '$experiencePath/reviews',
        body: {
          'sourceType': widget.row['sourceType'],
          'sourceId': widget.row['sourceId'],
          'targetId': widget.row['targetId'],
          'rating': _rating,
          'comment': _comment.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        context.lumiText('Chia sẻ trải nghiệm', 'Share your experience'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.row['name']?.toString() ?? 'LUMI'),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  tooltip: '${index + 1} ${context.lumiText('sao', 'stars')}',
                  onPressed: _saving
                      ? null
                      : () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            TextField(
              controller: _comment,
              maxLength: 1000,
              minLines: 3,
              maxLines: 5,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: context.lumiText(
                  'Cảm nhận của bạn',
                  'Your feedback',
                ),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.lumiText('Để sau', 'Later')),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(
            context.lumiText(
              _saving ? 'Đang gửi…' : 'Gửi đánh giá',
              _saving ? 'Sending…' : 'Submit review',
            ),
          ),
        ),
      ],
    ),
  );
}

class LumiCatalogActions extends StatefulWidget {
  const LumiCatalogActions({super.key, required this.type, required this.item});
  final String type;
  final Map<String, dynamic> item;
  @override
  State<LumiCatalogActions> createState() => _LumiCatalogActionsState();
}

class _LumiCatalogActionsState extends State<LumiCatalogActions> {
  bool _saved = false, _busy = false, _loaded = false;
  String? _uid;
  StreamSubscription<User?>? _auth;
  String get _id => widget.item['id']?.toString() ?? '';
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _load();
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) {
        return;
      }
      _uid = user?.uid;
      setState(() {
        _saved = false;
        _loaded = false;
      });
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant LumiCatalogActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type ||
        oldWidget.item['id'] != widget.item['id']) {
      _saved = false;
      _loaded = false;
      _load();
    }
  }

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_uid == null || _id.isEmpty) {
      return;
    }
    final uid = _uid, id = _id, type = widget.type;
    try {
      final response = await LumiApiClient.instance.get(
        '$experiencePath/favorites',
      );
      final rows = (response['data'] as List).whereType<Map>();
      if (mounted && uid == _uid && id == _id && type == widget.type) {
        setState(() {
          _saved = rows.any((r) => r['type'] == type && r['targetId'] == id);
          _loaded = true;
        });
      }
    } catch (_) {
      /* Explicit reload on tap; never overwrite an unknown saved state. */
    }
  }

  Future<void> _toggle() async {
    if (_busy) {
      return;
    }
    if (_uid == null) {
      _notice(
        context.lumiText(
          'Đăng nhập để lưu yêu thích.',
          'Sign in to save favorites.',
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (!_loaded) {
        await _load();
      }
      if (!mounted) {
        return;
      }
      if (!_loaded) {
        throw const LumiApiException(
          'Chưa tải được yêu thích. Vui lòng thử lại.',
        );
      }
      final wasSaved = _saved, uid = _uid;
      final path =
          '$experiencePath/favorites/${widget.type}/${Uri.encodeComponent(_id)}';
      if (wasSaved) {
        await LumiApiClient.instance.delete(path);
      } else {
        await LumiApiClient.instance.put(path);
      }
      if (mounted && uid == _uid) {
        setState(() => _saved = !wasSaved);
      }
    } catch (error) {
      _notice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _reviews() async {
    try {
      final response = await LumiApiClient.instance.get(
        '$experiencePath/reviews/${widget.type}/${Uri.encodeComponent(_id)}',
      );
      if (!mounted) {
        return;
      }
      final data = Map<String, dynamic>.from(response['data'] as Map);
      final rows = (data['reviews'] as List).whereType<Map>().toList();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .65,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  ctx.lumiText('Đánh giá đã xác thực', 'Verified reviews'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  data['average'] == null
                      ? ctx.lumiText('Chưa có đánh giá.', 'No reviews yet.')
                      : '${(data['average'] as num).toStringAsFixed(1)} / 5 · ${data['count']} ${ctx.lumiText('đánh giá', 'reviews')}',
                ),
                for (final row in rows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['rating']} ★ · ${ctx.lumiText('Khách hàng LUMI', 'LUMI customer')}',
                          ),
                          const SizedBox(height: 8),
                          Text(row['comment']?.toString() ?? ''),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      _notice(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: context.lumiText(
          _saved ? 'Bỏ yêu thích' : 'Lưu yêu thích',
          _saved ? 'Remove favorite' : 'Save favorite',
        ),
        onPressed: _id.isEmpty || _busy ? null : _toggle,
        icon: Icon(
          _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      IconButton(
        tooltip: context.lumiText('Đánh giá', 'Reviews'),
        onPressed: _id.isEmpty ? null : _reviews,
        icon: const Icon(Icons.star_outline_rounded),
      ),
    ],
  );
}
