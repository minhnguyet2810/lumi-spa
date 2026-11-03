import 'package:flutter/material.dart';
import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_adaptive.dart';
import '../../../../core/theme/lumi_style.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({
    super.key,
    this.initialAddress,
  });

  final LumiAddressItem? initialAddress;

  bool get isEditing => initialAddress != null;

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _provinceController;
  late final TextEditingController _districtController;
  late final TextEditingController _wardController;
  late final TextEditingController _streetController;

  late String _label;
  late bool _isDefault;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAddress;
    _nameController = TextEditingController(text: a?.recipientName ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _provinceController = TextEditingController(text: a?.province ?? '');
    _districtController = TextEditingController(text: a?.district ?? '');
    _wardController = TextEditingController(text: a?.ward ?? '');
    _streetController = TextEditingController(text: a?.street ?? '');
    _label = a?.label ?? 'Nhà riêng';
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: LumiAdaptive.text(label),
      hintText: hint != null ? LumiAdaptive.text(hint) : null,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: LumiAdaptive.color(LumiStyle.rose)) : null,
      filled: true,
      fillColor: LumiAdaptive.color(Colors.white, surface: true),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: LumiAdaptive.color(LumiStyle.line)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: LumiAdaptive.color(LumiStyle.line)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: LumiAdaptive.color(LumiStyle.rose), width: 1.5),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final address = LumiAddressItem(
      id: widget.initialAddress?.id ?? '',
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      province: _provinceController.text.trim(),
      district: _districtController.text.trim(),
      ward: _wardController.text.trim(),
      street: _streetController.text.trim(),
      label: _label,
      isDefault: _isDefault,
    );

    try {
      if (widget.isEditing) {
        await LumiAccountRepository.updateAddress(address);
      } else {
        await LumiAccountRepository.addAddress(address);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LumiAdaptive.text(
                widget.isEditing
                    ? 'Cập nhật địa chỉ thành công!'
                    : 'Thêm địa chỉ mới thành công!',
              ),
            ),
            backgroundColor: LumiAdaptive.color(LumiStyle.rose),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.initialAddress == null || _deleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LumiAdaptive.text('Xóa địa chỉ')),
        content: Text(
          LumiAdaptive.text(
            'Bạn có chắc chắn muốn xóa địa chỉ này khỏi sổ địa chỉ không?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(LumiAdaptive.text('Hủy')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(LumiAdaptive.text('Xóa')),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await LumiAccountRepository.deleteAddress(widget.initialAddress!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LumiAdaptive.text('Đã xóa địa chỉ thành công.'))),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      backgroundColor: LumiAdaptive.color(LumiStyle.canvas, surface: true),
      appBar: AppBar(
        title: Text(
          LumiAdaptive.text(
            widget.isEditing ? 'Chỉnh sửa địa chỉ' : 'Địa chỉ mới',
          ),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          children: [
            _sectionHeader('Liên hệ'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Họ và tên', hint: 'Ví dụ: Nguyễn Văn A', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Vui lòng nhập họ và tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Số điện thoại', hint: 'Ví dụ: 0901234567', icon: Icons.phone_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                final cleaned = v.trim();
                if (!RegExp(r'^[0-9+().\s-]{8,20}$').hasMatch(cleaned)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            _sectionHeader('Địa chỉ nhận hàng'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _provinceController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Tỉnh / Thành phố', hint: 'Ví dụ: TP. Hồ Chí Minh, Hà Nội...', icon: Icons.location_city_outlined),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _districtController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Quận / Huyện', hint: 'Ví dụ: Quận 1, Cầu Giấy...'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _wardController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Phường / Xã', hint: 'Ví dụ: Phường Bến Nghé...'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetController,
              maxLines: 2,
              decoration: _inputDecoration(
                'Tên đường, Tòa nhà, Số nhà',
                hint: 'Ví dụ: 123 Lê Lợi, Chung cư Vinhome Central Park...',
                icon: Icons.home_outlined,
              ),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Vui lòng nhập số nhà, tên đường cụ thể' : null,
            ),

            const SizedBox(height: 24),
            _sectionHeader('Cài đặt'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: LumiAdaptive.color(Colors.white, surface: true),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LumiAdaptive.color(LumiStyle.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LumiAdaptive.text('Loại địa chỉ:'),
                    style: LumiAdaptive.style(
                      LumiStyle.label().copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _labelChip('Nhà riêng', Icons.home_outlined),
                      const SizedBox(width: 12),
                      _labelChip('Văn phòng', Icons.business_outlined),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LumiAdaptive.text('Đặt làm địa chỉ mặc định'),
                              style: LumiAdaptive.style(
                                LumiStyle.body(size: 15).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LumiAdaptive.text('Tự động chọn khi đặt dịch vụ và thanh toán đơn hàng'),
                              style: LumiAdaptive.style(
                                LumiStyle.body(size: 13, color: LumiAdaptive.color(LumiStyle.ink.withValues(alpha: .6))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isDefault,
                        activeTrackColor: LumiAdaptive.color(LumiStyle.rose),
                        onChanged: (val) => setState(() => _isDefault = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (widget.isEditing) ...[
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: (_saving || _deleting) ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: Text(
                    LumiAdaptive.text(_deleting ? 'Đang xóa...' : 'Xóa địa chỉ này'),
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: LumiAdaptive.color(Colors.white, surface: true),
            border: Border(top: BorderSide(color: LumiAdaptive.color(LumiStyle.line))),
          ),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: (_saving || _deleting) ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: LumiAdaptive.color(LumiStyle.rose),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      LumiAdaptive.text('Hoàn thành'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _sectionHeader(String title) => Text(
    LumiAdaptive.text(title),
    style: LumiAdaptive.style(
      LumiStyle.label().copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: LumiAdaptive.color(LumiStyle.plum),
      ),
    ),
  );

  Widget _labelChip(String label, IconData icon) {
    final isSelected = _label == label;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _label = label);
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : LumiAdaptive.color(LumiStyle.ink),
      ),
      label: Text(
        LumiAdaptive.text(label),
        style: TextStyle(
          color: isSelected ? Colors.white : LumiAdaptive.color(LumiStyle.ink),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      selectedColor: LumiAdaptive.color(LumiStyle.rose),
      backgroundColor: LumiAdaptive.color(LumiStyle.canvas, surface: true),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? LumiAdaptive.color(LumiStyle.rose) : LumiAdaptive.color(LumiStyle.line),
        ),
      ),
    );
  }
}

