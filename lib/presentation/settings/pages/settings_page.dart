/// Settings page — Store information management.
///
/// Allows user to input store name, address, phone number,
/// and select logo/QR images for invoice headers.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/presentation/settings/bloc/store_info_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _logoPath = '';
  String _qrImagePath = '';
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _initFromState(StoreInfoState state) {
    if (!_initialized && state.storeInfo != null) {
      _nameCtrl.text = state.storeInfo!.name;
      _addressCtrl.text = state.storeInfo!.address;
      _phoneCtrl.text = state.storeInfo!.phone;
      _logoPath = state.storeInfo!.logoPath;
      _qrImagePath = state.storeInfo!.qrImagePath;
      _initialized = true;
    } else if (!_initialized &&
        state.status == StoreInfoStatus.loaded) {
      _initialized = true;
    }
  }

  Future<String> _copyToAppDir(String sourcePath, String prefix) async {
    final appDir = await getApplicationDocumentsDirectory();
    final storeDir = Directory(p.join(appDir.path, 'fishcash_store'));
    if (!storeDir.existsSync()) {
      storeDir.createSync(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final destPath =
        p.join(storeDir.path, '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
        dialogTitle: 'Chọn logo cửa hàng',
      );
      if (result != null && result.files.single.path != null) {
        final savedPath =
            await _copyToAppDir(result.files.single.path!, 'logo');
        setState(() => _logoPath = savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _pickQrImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
        dialogTitle: 'Chọn ảnh QR thanh toán',
      );
      if (result != null && result.files.single.path != null) {
        final savedPath =
            await _copyToAppDir(result.files.single.path!, 'qr');
        setState(() => _qrImagePath = savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      context.read<StoreInfoBloc>().add(StoreInfoSaveRequested(
            name: _nameCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            logoPath: _logoPath,
            qrImagePath: _qrImagePath,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: BlocConsumer<StoreInfoBloc, StoreInfoState>(
        listener: (context, state) {
          if (state.status == StoreInfoStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Đã lưu thông tin cửa hàng'),
                  ],
                ),
                backgroundColor: OceanTheme.sellGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state.status == StoreInfoStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.errorMessage}'),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          _initFromState(state);

          if (state.status == StoreInfoStatus.loading ||
              state.status == StoreInfoStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      _buildHeaderCard(colorScheme, textTheme),
                      const SizedBox(height: 24),

                      // Store info form
                      _buildInfoCard(colorScheme, textTheme),
                      const SizedBox(height: 24),

                      // Images section
                      _buildImagesCard(colorScheme, textTheme),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: state.status == StoreInfoStatus.saving
                              ? null
                              : _save,
                          icon: state.status == StoreInfoStatus.saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            state.status == StoreInfoStatus.saving
                                ? 'Đang lưu...'
                                : 'Lưu thông tin',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [OceanTheme.oceanDeep, OceanTheme.oceanPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: OceanTheme.oceanPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin cửa hàng',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thông tin này sẽ hiển thị trên hóa đơn và báo cáo',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Thông tin cơ bản',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên cửa hàng *',
                hintText: 'VD: Vựa Cá Bình Minh',
                prefixIcon: Icon(Icons.storefront),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập tên cửa hàng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                hintText: 'VD: 123 Đường Cá, Phường Biển, TP. Nha Trang',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: 'VD: 0901 234 567',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Hình ảnh',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Logo picker
                Expanded(
                  child: _ImagePickerTile(
                    label: 'Logo cửa hàng',
                    imagePath: _logoPath,
                    icon: Icons.image,
                    onPick: _pickLogo,
                    onClear: () => setState(() => _logoPath = ''),
                  ),
                ),
                const SizedBox(width: 16),
                // QR picker
                Expanded(
                  child: _ImagePickerTile(
                    label: 'QR thanh toán',
                    imagePath: _qrImagePath,
                    icon: Icons.qr_code,
                    onPick: _pickQrImage,
                    onClear: () => setState(() => _qrImagePath = ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chọn ảnh xong nhớ nhấn "Lưu thông tin" bên dưới để lưu lại.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable image picker tile with preview
class _ImagePickerTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final IconData icon;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImagePickerTile({
    required this.label,
    required this.imagePath,
    required this.icon,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Overlay label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Clear button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black38,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onClear,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child:
                              Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 40,
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhấn để chọn ảnh',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
