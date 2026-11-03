import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/settings/app_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;
  final _preferences = AppPreferences.instance;

  Future<void> _save(Future<void> Function() action) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.lumiText(
                'Chưa lưu được lựa chọn. Vui lòng thử lại.',
                'Could not save your preference. Please try again.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _preferences,
    builder: (context, _) {
      final theme = Theme.of(context);
      final dark = theme.brightness == Brightness.dark;
      final colors = theme.colorScheme;
      final ink = colors.onSurface;
      final muted = colors.onSurfaceVariant;
      final peach = dark ? const Color(0xFF53382D) : const Color(0xFFFBE4D6);
      final sky = dark ? const Color(0xFF2C4651) : const Color(0xFFE1EFF5);
      final sage = dark ? const Color(0xFF374638) : const Color(0xFFE9EFDE);
      String tr(String vi, String en) => context.lumiText(vi, en);
      final duration = Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
      );

      Widget heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 28, 2, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ),
      );
      Widget check(bool selected) => Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        size: 23,
        color: selected ? colors.primary : muted,
      );
      Widget language(String code, String title, String detail, Color fill) {
        final selected = _preferences.locale.languageCode == code;
        return Semantics(
          selected: selected,
          child: AnimatedContainer(
            duration: duration,
            decoration: BoxDecoration(
              color: selected ? fill : colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving
                    ? null
                    : () => _save(() => _preferences.setLanguage(code)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          code.toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              detail,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      check(selected),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      Widget preview(ThemeMode mode) {
        final night = mode == ThemeMode.dark;
        final automatic = mode == ThemeMode.system;
        return ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 106,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: automatic
                      ? [
                          const Color(0xFFFFF8EF),
                          const Color(0xFFFFF8EF),
                          const Color(0xFF344E5B),
                          const Color(0xFF344E5B),
                        ]
                      : night
                      ? [const Color(0xFF344E5B), const Color(0xFF303940)]
                      : [const Color(0xFFFBE7DC), const Color(0xFFDCECF1)],
                  stops: automatic ? const [0, 0.5, 0.5, 1] : null,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                automatic
                    ? Icons.brightness_auto_rounded
                    : night
                    ? Icons.nightlight_round
                    : Icons.wb_sunny_rounded,
                size: 28,
                color: night || automatic
                    ? const Color(0xFFF5BEA5)
                    : const Color(0xFFA5553E),
              ),
            ),
          ),
        );
      }

      Widget appearance(ThemeMode mode, String label, Color fill) {
        final selected = _preferences.themeMode == mode;
        return Semantics(
          selected: selected,
          child: AnimatedContainer(
            duration: duration,
            decoration: BoxDecoration(
              color: selected ? fill : colors.surface,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(23),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving
                    ? null
                    : () => _save(() => _preferences.setTheme(mode)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      preview(mode),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          check(selected),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text(tr('Cài đặt', 'Settings'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? [
                          const Color(0xFF5A3D32),
                          const Color(0xFF35454B),
                          const Color(0xFF263E48),
                        ]
                      : [
                          const Color(0xFFF8D5C2),
                          const Color(0xFFF3E7D9),
                          const Color(0xFFCBE5EE),
                        ],
                  stops: const [0, 0.48, 1],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF63574E)
                      : const Color(0xFFF8EDE3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF557C90)
                        .withValues(alpha: dark ? 0.08 : 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (dark ? Colors.black : Colors.white)
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(Icons.tune_rounded, color: ink, size: 28),
                        ),
                        const Spacer(),
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              for (final color in [
                                const Color(0xFFF2B89B),
                                const Color(0xFFA9CEDD),
                                const Color(0xFFB9C9A8),
                              ])
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      tr('LUMI theo cách của bạn', 'Make LUMI yours'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(
                        'Một không gian hợp với bạn, từ ngôn ngữ đến sắc màu.',
                        'Your own space, from language to appearance.',
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ink,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            heading(
              tr('Ngôn ngữ', 'Language'),
              tr(
                'Chọn cách LUMI trò chuyện với bạn.',
                'Choose how LUMI speaks to you.',
              ),
            ),
            language(
              'vi',
              'Tiếng Việt',
              tr('Gần gũi và quen thuộc', 'Vietnamese'),
              peach,
            ),
            const SizedBox(height: 12),
            language(
              'en',
              'English',
              tr('Trải nghiệm bằng tiếng Anh', 'Use LUMI in English'),
              sky,
            ),
            heading(
              tr('Giao diện', 'Appearance'),
              tr(
                'Chọn một sắc thái cho ngày của bạn.',
                'Set the mood for your day.',
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow =
                    constraints.maxWidth < 390 ||
                    MediaQuery.textScalerOf(context).scale(16) > 21;
                final cards = [
                  appearance(ThemeMode.light, tr('Sáng', 'Light'), peach),
                  appearance(ThemeMode.dark, tr('Tối', 'Dark'), sky),
                  appearance(ThemeMode.system, tr('Hệ thống', 'System'), sage),
                ];
                if (narrow) {
                  return Column(
                    children: [
                      for (final card in cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                'Hệ thống: tự đổi sáng hoặc tối theo thiết bị.',
                'System: automatically follow your device appearance.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            heading(
              tr('Tài khoản', 'Account'),
              tr(
                'Thông tin của bạn, luôn trong tầm tay.',
                'Your details, always within reach.',
              ),
            ),
            Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(23),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/profile/edit'),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: sage,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.person_outline_rounded, color: ink),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Thông tin cá nhân', 'Personal information'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr(
                                'Cập nhật họ tên và số điện thoại',
                                'Update your name and phone number',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: muted,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(
                      'Lựa chọn được lưu trên thiết bị này.',
                      'Your preferences are saved on this device.',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      );
    },
  );
}
