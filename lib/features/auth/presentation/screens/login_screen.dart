import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _ambientController;
  late final Animation<double> _bannerZoom;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )..repeat(reverse: true);
    _bannerZoom = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );
    _contentFade = CurvedAnimation(
      parent: _motionController,
      curve: const Interval(0.08, 0.80, curve: Curves.easeOut),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _motionController,
            curve: const Interval(0.08, 0.88, curve: Curves.easeOutCubic),
          ),
        );
    _motionController.forward();
  }

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _ambientController.dispose();
    _motionController.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.';
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Không thể kết nối mạng. Hãy thử lại.';
      default:
        return 'Không thể xác thực tài khoản: ${e.code}';
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Đồng bộ hồ sơ Firestore với Firebase Auth, không ghi đè hồ sơ đã có.
  // Chỉ lưu dữ liệu cơ bản; không lưu mật khẩu hoặc quyền quản trị.
  Future<void> _syncUserProfile(User user, {String? registeredName}) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final existing = await doc.get();
    if (existing.exists) return;

    final name = (registeredName ?? user.displayName ?? '').trim();
    await doc.set({
      'uid': user.uid,
      'displayName': name,
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _submit() async {
    if (_busy) return;

    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _message('Vui lòng nhập email và mật khẩu.');
      return;
    }
    if (_register && name.isEmpty) {
      _message('Vui lòng nhập tên của bạn.');
      return;
    }
    if (_register && password.length < 6) {
      _message('Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }

    setState(() => _busy = true);
    try {
      if (_register) {
        final result = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await result.user?.updateDisplayName(name);
        await result.user?.reload();
        if (result.user != null) {
          try {
            await _syncUserProfile(result.user!, registeredName: name);
          } on FirebaseException {
            _message(
              'Tài khoản đã tạo, nhưng chưa lưu được hồ sơ. Hãy kiểm tra Firestore Rules rồi đăng nhập lại.',
            );
            return;
          }
        }
      } else {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        if (credential.user != null) {
          try {
            await _syncUserProfile(credential.user!);
          } on FirebaseException {
            // Không chặn đăng nhập nếu Firestore tạm thời không khả dụng.
            // Hồ sơ sẽ được thử tạo lại ở lần đăng nhập tiếp theo.
          }
        }
      }

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/welcome-back');
      }
    } on FirebaseAuthException catch (e) {
      _message(_errorMessage(e));
    } catch (_) {
      _message('Đã có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _message('Nhập email trước khi đặt lại mật khẩu.');
      return;
    }
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _message(
        'Nếu email hợp lệ, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.',
      );
    } on FirebaseAuthException catch (e) {
      _message(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _ink = Color(0xFF342C32);
  static const _rose = Color(0xFFB77489);
  static const _soft = Color(0xFFF0F5F2);

  InputDecoration _pill(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF89938E)),
    prefixIcon: Icon(icon, color: const Color(0xFF77877E), size: 20),
    filled: true,
    fillColor: _soft,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: _rose, width: 1.5),
    ),
  );

  void _returnToGuest() {
    if (_busy) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final registering = _register;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, size) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _returnToGuest,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                        label: const Text('Quay lại'),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: SizedBox(
                        height: size.maxHeight < 690 ? 195 : 245,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedBuilder(
                              animation: _bannerZoom,
                              builder: (context, child) => Transform.scale(
                                scale: _bannerZoom.value,
                                child: child,
                              ),
                              child: Image.asset(
                                'assets/images/welcome_spa_3.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xB5362730),
                                    Color(0x00362730),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                24,
                                22,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LUMI.',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    'Your little escape,\nright here.',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'SPA & WELLNESS',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: SlideTransition(
                          position: _contentSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                registering ? 'Create Account' : 'Welcome Back',
                                style: GoogleFonts.dmSans(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.9,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 21),
                              if (registering) ...[
                                TextField(
                                  controller: _name,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: _pill(
                                    'Your name',
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                const SizedBox(height: 13),
                              ],
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: _pill(
                                  'Email address',
                                  Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 13),
                              TextField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: [
                                  registering
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!_busy) _submit();
                                },
                                decoration:
                                    _pill(
                                      'Password',
                                      Icons.lock_outline_rounded,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF89938E),
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 13),
                              if (!registering)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: _rose,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        'Stay signed in',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: const Color(0xFF767676),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _busy ? null : _resetPassword,
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _rose,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 17),
                              SizedBox(
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C4656),
                                        Color(0xFFD39AA9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _busy ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                    ),
                                    child: _busy
                                        ? const SizedBox(
                                            width: 21,
                                            height: 21,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            registering ? 'Sign Up' : 'Log In',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE4E4E4)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'LUMI SPA & WELLNESS',
                                      style: GoogleFonts.dmSans(
                                        color: const Color(0xFF9A9A9A),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE4E4E4)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    registering
                                        ? 'Already have an account?'
                                        : "Don't have an account?",
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: const Color(0xFF8A8A8A),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _register = !_register,
                                          ),
                                    child: Text(
                                      registering ? 'Log In' : 'Sign Up',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _rose,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _busy ? null : _returnToGuest,
                                child: const Text(
                                  'Tiếp tục khám phá mà không đăng nhập',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
