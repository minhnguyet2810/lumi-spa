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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
    body: FutureBuilder<LumiAccountProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: LumiStyle.rose),
          );
        }
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Thông tin cá nhân', style: LumiStyle.heading(size: 36)),
            const SizedBox(height: 8),
            Text(
              'Cập nhật họ tên và số điện thoại của bạn.',
              style: LumiStyle.body(),
            ),
            const SizedBox(height: 24),
            Text('Email', style: LumiStyle.label()),
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
                  Text('Họ và tên', style: LumiStyle.label()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'Nhập họ và tên',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return 'Vui lòng nhập họ và tên.';
                      if (name.length > 100) return 'Tên không quá 100 ký tự.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Số điện thoại', style: LumiStyle.label()),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Nhập số điện thoại',
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
              Text(_error!, style: LumiStyle.body(color: LumiStyle.rose)),
            ],
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: LumiStyle.plum,
                foregroundColor: LumiStyle.ivory,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    ),
  );

  Widget _errorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: LumiStyle.rose, size: 40),
          const SizedBox(height: 14),
          Text('Không tải được hồ sơ', style: LumiStyle.heading(size: 30)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: LumiStyle.body()),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => _profileFuture = _loadProfile()),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}
