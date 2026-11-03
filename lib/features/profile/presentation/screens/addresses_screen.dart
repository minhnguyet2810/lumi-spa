import 'package:flutter/material.dart';
import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_adaptive.dart';
import '../../../../core/theme/lumi_style.dart';
import 'add_edit_address_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({
    super.key,
    this.isSelecting = false,
    this.selectedAddressId,
  });

  /// Nếu true, màn hình được mở từ Checkout để chọn địa chỉ nhận hàng
  final bool isSelecting;
  final String? selectedAddressId;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late Future<List<LumiAddressItem>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _addressesFuture = LumiAccountRepository.fetchAddresses();
    });
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddEditAddressScreen(),
      ),
    );
    if (result == true && mounted) {
      _reload();
    }
  }

  Future<void> _editAddress(LumiAddressItem address) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddEditAddressScreen(initialAddress: address),
      ),
    );
    if (result == true && mounted) {
      _reload();
    }
  }

  Future<void> _setDefault(LumiAddressItem address) async {
    try {
      await LumiAccountRepository.setDefaultAddress(address.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LumiAdaptive.text('Đã đặt làm địa chỉ mặc định.'),
            ),
            backgroundColor: LumiAdaptive.color(LumiStyle.rose),
          ),
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _deleteAddress(LumiAddressItem address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LumiAdaptive.text('Xóa địa chỉ')),
        content: Text(
          LumiAdaptive.text('Bạn có chắc muốn xóa địa chỉ này không?'),
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

    try {
      await LumiAccountRepository.deleteAddress(address.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LumiAdaptive.text('Đã xóa địa chỉ thành công.'))),
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
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
            widget.isSelecting ? 'Chọn địa chỉ nhận hàng' : 'Địa chỉ nhận hàng',
          ),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: LumiAdaptive.color(LumiStyle.rose),
        child: FutureBuilder<List<LumiAddressItem>>(
          future: _addressesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: LumiAdaptive.color(LumiStyle.rose),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        LumiAdaptive.text('Không thể tải danh sách địa chỉ.'),
                        style: LumiAdaptive.style(LumiStyle.body()),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: Text(LumiAdaptive.text('Thử lại')),
                      ),
                    ],
                  ),
                ),
              );
            }

            final addresses = snapshot.data ?? [];

            if (addresses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: LumiAdaptive.color(LumiStyle.blushSurface, surface: true),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_off_outlined,
                          size: 60,
                          color: LumiAdaptive.color(LumiStyle.rose),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        LumiAdaptive.text('Chưa có địa chỉ nhận hàng nào'),
                        style: LumiAdaptive.style(
                          LumiStyle.heading(size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LumiAdaptive.text(
                          'Lưu địa chỉ nhận hàng để đặt mua mỹ phẩm và nhận sản phẩm nhanh chóng hơn.',
                        ),
                        textAlign: TextAlign.center,
                        style: LumiAdaptive.style(
                          LumiStyle.body(color: LumiAdaptive.color(LumiStyle.ink.withValues(alpha: .6))),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _addNewAddress,
                        icon: const Icon(Icons.add),
                        label: Text(LumiAdaptive.text('Thêm địa chỉ mới')),
                        style: FilledButton.styleFrom(
                          backgroundColor: LumiAdaptive.color(LumiStyle.rose),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = addresses[index];
                return _buildAddressCard(item);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: LumiAdaptive.color(Colors.white, surface: true),
            border: Border(top: BorderSide(color: LumiAdaptive.color(LumiStyle.line))),
          ),
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _addNewAddress,
              icon: const Icon(Icons.add, size: 22),
              label: Text(
                LumiAdaptive.text('Thêm Địa Chỉ Mới'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: LumiAdaptive.color(LumiStyle.rose),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildAddressCard(LumiAddressItem address) {
    final isSelected = widget.isSelecting && widget.selectedAddressId == address.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isSelecting
            ? () => Navigator.of(context).pop(address)
            : () => _editAddress(address),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LumiAdaptive.color(Colors.white, surface: true),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? LumiAdaptive.color(LumiStyle.rose)
                  : LumiAdaptive.color(LumiStyle.line),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng họ tên, số điện thoại, nút sửa
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    address.recipientName,
                    style: LumiAdaptive.style(
                      LumiStyle.body(size: 16).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '|',
                    style: TextStyle(
                      color: LumiAdaptive.color(LumiStyle.line),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    address.phone,
                    style: LumiAdaptive.style(
                      LumiStyle.body(
                        size: 15,
                        color: LumiAdaptive.color(LumiStyle.ink.withValues(alpha: .75)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _editAddress(address),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        LumiAdaptive.text('Thiết lập'),
                        style: TextStyle(
                          color: LumiAdaptive.color(LumiStyle.rose),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Địa chỉ cụ thể
              Text(
                address.street,
                style: LumiAdaptive.style(
                  LumiStyle.body(size: 14),
                ),
              ),

              // Phường, Quận, Tỉnh
              if (address.ward.isNotEmpty || address.district.isNotEmpty || address.province.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  [address.ward, address.district, address.province]
                      .where((s) => s.isNotEmpty)
                      .join(', '),
                  style: LumiAdaptive.style(
                    LumiStyle.body(
                      size: 13,
                      color: LumiAdaptive.color(LumiStyle.ink.withValues(alpha: .65)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Huy hiệu Shopee: [Mặc định] [Nhà riêng / Văn phòng] và thao tác
              Row(
                children: [
                  if (address.isDefault) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: LumiAdaptive.color(const Color(0xFFFBE7DC), surface: true),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: LumiAdaptive.color(LumiStyle.rose)),
                      ),
                      child: Text(
                        LumiAdaptive.text('Mặc định'),
                        style: TextStyle(
                          color: LumiAdaptive.color(LumiStyle.rose),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: LumiAdaptive.color(const Color(0xFFE6F1F5), surface: true),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      LumiAdaptive.text(address.label),
                      style: const TextStyle(
                        color: Color(0xFF406779),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!address.isDefault) ...[
                    TextButton(
                      onPressed: () => _setDefault(address),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        LumiAdaptive.text('Đặt mặc định'),
                        style: TextStyle(
                          fontSize: 12,
                          color: LumiAdaptive.color(LumiStyle.ink.withValues(alpha: .7)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: () => _deleteAddress(address),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.redAccent.withValues(alpha: .7),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

