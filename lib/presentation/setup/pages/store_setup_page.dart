import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/presentation/sync/bloc/sync_bloc.dart';

class StoreSetupPage extends StatefulWidget {
  const StoreSetupPage({super.key});

  @override
  State<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends State<StoreSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSetup() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ConnectionBloc>().add(StoreSetupRequested(
          _storeNameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ConnectionBloc, ServerConnectionState>(
      listener: (context, state) {
        if (state.status == ConnectionStatus.connected) {
          // Setup done → go to Dashboard
          context.go('/');
        } else if (state.status == ConnectionStatus.error &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: OceanTheme.oceanPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      size: 64,
                      color: OceanTheme.oceanPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Chào mừng đến FishCash',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhập thông tin cửa hàng của bạn để bắt đầu',
                    style: TextStyle(
                      color: colorScheme.outline,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _storeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên cửa hàng *',
                            hintText: 'VD: Cá Tươi Sài Gòn',
                            prefixIcon: Icon(Icons.storefront_rounded),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vui lòng nhập tên cửa hàng'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            hintText: 'VD: 0901234567',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ',
                            hintText: 'VD: 123 Nguyễn Huệ, Q1, TP.HCM',
                            prefixIcon: Icon(Icons.location_on_rounded),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSetup(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Setup button
                  BlocBuilder<ConnectionBloc, ServerConnectionState>(
                    builder: (context, state) {
                      final isLoading =
                          state.status == ConnectionStatus.loading;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: isLoading ? null : _handleSetup,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.rocket_launch_rounded),
                          label: Text(
                            isLoading
                                ? 'Đang thiết lập...'
                                : 'Bắt đầu sử dụng',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
