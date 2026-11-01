import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wraps the navigator as well as its initial page, so pushed admin pages
/// disappear when the account changes or a refreshed token loses its claim.
class AdminAccessGate extends StatefulWidget {
  const AdminAccessGate({super.key, required this.child});
  final Widget child;
  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends State<AdminAccessGate> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<User?>? _subscription;
  bool _allowed = false;
  bool _loading = true;
  bool _signingIn = false;
  bool _hidePassword = true;
  String? _message;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseAuth.instance.idTokenChanges().listen(
      (_) => _check(),
    );
  }

  Future<void> _check({bool refresh = false}) async {
    if (!mounted) {
      return;
    }
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _allowed = false;
      _message = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdTokenResult(refresh);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _allowed = token?.claims?['admin'] == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loading = false;
        _message = 'Không thể kiểm tra quyền. Vui lòng đăng nhập lại.';
      });
    }
  }

  Future<void> _signIn() async {
    if (_signingIn) {
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() {
        _message = 'Vui lòng nhập email và mật khẩu.';
      });
      return;
    }
    setState(() {
      _signingIn = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      _password.clear();
      await _check(refresh: true);
    } on FirebaseAuthException {
      if (mounted) {
        setState(() {
          _message = 'Không thể đăng nhập. Hãy kiểm tra thông tin tài khoản và kết nối.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _signingIn = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = FirebaseAuth.instance.currentUser;
    if (_allowed && user != null) {
      return KeyedSubtree(key: ValueKey(user.uid), child: widget.child);
    }
    const ink = Color(0xFF403735);
    const terracotta = Color(0xFFA5553E);
    final signedIn = user != null;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDDECF0).withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -120,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF7DCCB).withValues(alpha: 0.55),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 48
                          ? constraints.maxHeight - 48
                          : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF6D2BC),
                                    Color(0xFFF1E8D9),
                                    Color(0xFFD8EAF0),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: terracotta.withValues(alpha: 0.07),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(11),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            17,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.spa_outlined,
                                          color: terracotta,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'LUMI',
                                              style: GoogleFonts.dmSans(
                                                color: ink,
                                                fontSize: 30,
                                                letterSpacing: 3,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'KHÔNG GIAN QUẢN TRỊ',
                                              style: GoogleFonts.dmSans(
                                                color: const Color(0xFF816453),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.auto_awesome_outlined,
                                        color: terracotta,
                                        size: 21,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Chăm chút trải nghiệm.\nKết nối từng ngày.',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      color: ink,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final label in [
                                        'Lịch hẹn',
                                        'Đơn hàng',
                                        'Khách hàng',
                                      ])
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.55,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            label,
                                            style: GoogleFonts.dmSans(
                                              color: const Color(0xFF725A4F),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.all(23),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFEADDD3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ink.withValues(alpha: 0.04),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    signedIn
                                        ? 'Quyền truy cập quản trị'
                                        : 'Chào mừng trở lại.',
                                    style: GoogleFonts.dmSans(
                                      color: ink,
                                      fontSize: 23,
                                      height: 1.25,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    signedIn
                                        ? 'Tài khoản hiện tại chưa được xác nhận quyền truy cập portal.'
                                        : 'Đăng nhập để bắt đầu quản lý LUMI.',
                                    style: GoogleFonts.dmSans(
                                      color: const Color(0xFF887970),
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 23),
                                  if (user == null) ...[
                                    AutofillGroup(
                                      child: Column(
                                        children: [
                                          _loginField(
                                            controller: _email,
                                            label: 'Email quản trị',
                                            hint: 'you@example.com',
                                            icon: Icons.mail_outline_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            autofillHints: const [
                                              AutofillHints.username,
                                            ],
                                          ),
                                          const SizedBox(height: 17),
                                          _loginField(
                                            controller: _password,
                                            label: 'Mật khẩu',
                                            hint: 'Nhập mật khẩu',
                                            icon: Icons.lock_outline_rounded,
                                            obscureText: _hidePassword,
                                            autofillHints: const [
                                              AutofillHints.password,
                                            ],
                                            suffix: IconButton(
                                              tooltip: _hidePassword
                                                  ? 'Hiện mật khẩu'
                                                  : 'Ẩn mật khẩu',
                                              onPressed: _signingIn
                                                  ? null
                                                  : () => setState(() {
                                                      _hidePassword =
                                                          !_hidePassword;
                                                    }),
                                              icon: Icon(
                                                _hidePassword
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                size: 20,
                                                color: const Color(0xFF94847A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F0F3),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.admin_panel_settings_outlined,
                                            color: Color(0xFF4E7280),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              user.email ?? '',
                                              style: GoogleFonts.dmSans(
                                                color: ink,
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 13),
                                    Text(
                                      'Liên hệ người quản lý để được cấp quyền. Nếu vừa được cấp, hãy làm mới quyền hoặc đăng nhập lại.',
                                      style: GoogleFonts.dmSans(
                                        color: const Color(0xFF887970),
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                  if (_message != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEEE6),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Text(
                                        _message!,
                                        style: GoogleFonts.dmSans(
                                          color: const Color(0xFF944932),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 23),
                                  FilledButton(
                                    onPressed: _signingIn
                                        ? null
                                        : (signedIn
                                              ? () => _check(refresh: true)
                                              : _signIn),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: terracotta,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFFE6CAB8,
                                      ),
                                      minimumSize: const Size.fromHeight(53),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_signingIn) ...[
                                          const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Flexible(
                                          child: Text(
                                            _signingIn
                                                ? 'Đang đăng nhập…'
                                                : (signedIn
                                                      ? 'Làm mới quyền'
                                                      : 'Đăng nhập quản trị'),
                                            style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (!_signingIn) ...[
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (signedIn)
                                    TextButton(
                                      onPressed: () =>
                                          FirebaseAuth.instance.signOut(),
                                      child: Text(
                                        'Đăng nhập tài khoản khác',
                                        style: GoogleFonts.dmSans(
                                          color: terracotta,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 19),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: Color(0xFF998779),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Dành riêng cho tài khoản được cấp quyền',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: const Color(0xFF998779),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<String>? autofillHints,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: const Color(0xFF66554B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !_signingIn,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: keyboardType == TextInputType.emailAddress,
          textInputAction: keyboardType == TextInputType.emailAddress
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: keyboardType == TextInputType.emailAddress
              ? null
              : (_) => _signIn(),
          style: GoogleFonts.dmSans(
            color: const Color(0xFF403735),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: const Color(0xFFAD9C90),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFAD7560), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFFBF7F2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEADDD3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEADDD3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFA5553E),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
