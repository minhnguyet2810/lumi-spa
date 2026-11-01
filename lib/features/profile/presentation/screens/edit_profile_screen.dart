import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';

import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_style.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late Future<LumiAccountProfile> _profileFuture;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<LumiAccountProfile> _loadProfile() async {
    final profile = await LumiAccountRepository.fetchProfile();
    _nameController.text = profile.displayName;
    _phoneController.text = profile.phone;
    return profile;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await LumiAccountRepository.updateProfile(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      appBar: AppBar(title: Text(LumiAdaptive.text('Chỉnh sửa hồ sơ'))),
      body: FutureBuilder<LumiAccountProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: LumiAdaptive.color(LumiStyle.rose),
              ),
            );
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                LumiAdaptive.text('Thông tin cá nhân'),
                style: LumiAdaptive.style(LumiStyle.heading(size: 36)),
              ),
              const SizedBox(height: 8),
              Text(
                LumiAdaptive.text('Cập nhật họ tên và số điện thoại của bạn.'),
                style: LumiAdaptive.style(LumiStyle.body()),
              ),
              const SizedBox(height: 24),
              Text(
                LumiAdaptive.text('Email'),
                style: LumiAdaptive.style(LumiStyle.label()),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: snapshot.data!.email,
                enabled: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LumiAdaptive.text('Họ và tên'),
                      style: LumiAdaptive.style(LumiStyle.label()),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: LumiAdaptive.optionalText('Nhập họ và tên'),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) {
                          return 'Vui lòng nhập họ và tên.';
                        }
                        if (name.length > 100) {
                          return 'Tên không quá 100 ký tự.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      LumiAdaptive.text('Số điện thoại'),
                      style: LumiAdaptive.style(LumiStyle.label()),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: LumiAdaptive.optionalText(
                          'Nhập số điện thoại',
                        ),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final phone = value?.trim() ?? '';
                        if (!RegExp(r'^[0-9+().\s-]{8,20}$').hasMatch(phone)) {
                          return 'Số điện thoại phải có 8–20 ký tự hợp lệ.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  LumiAdaptive.text(_error!),
                  style: LumiAdaptive.style(
                    LumiStyle.body(
                      color: LumiAdaptive.color(LumiStyle.rose, surface: true),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: LumiAdaptive.style(
                  FilledButton.styleFrom(
                    backgroundColor: LumiAdaptive.color(
                      LumiStyle.plum,
                      surface: true,
                    ),
                    foregroundColor: LumiAdaptive.color(LumiStyle.ivory),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LumiAdaptive.color(Colors.white),
                        ),
                      )
                    : Text(LumiAdaptive.text('Lưu thay đổi')),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _errorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: LumiAdaptive.color(LumiStyle.rose),
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            LumiAdaptive.text('Không tải được hồ sơ'),
            style: LumiAdaptive.style(LumiStyle.heading(size: 30)),
          ),
          const SizedBox(height: 8),
          Text(
            LumiAdaptive.text(message),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(LumiStyle.body()),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => _profileFuture = _loadProfile()),
            child: Text(LumiAdaptive.text('Thử lại')),
          ),
        ],
      ),
    ),
  );
}
