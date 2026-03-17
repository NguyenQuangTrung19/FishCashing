/// Connection Settings Page — server info and connectivity status.
///
/// Replaces the old SyncSettingsPage. Shows connection status,
/// server URL config, and store info. No login/register form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/presentation/sync/bloc/sync_bloc.dart';

class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final _serverUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ConnectionBloc>().add(const ConnectionInitRequested());
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectionBloc, ServerConnectionState>(
      listener: (context, state) {
        if (state.status == ConnectionStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state.serverUrl != null && _serverUrlController.text.isEmpty) {
          _serverUrlController.text = state.serverUrl!;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Kết nối & Sao lưu')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Status Card ---
                _buildStatusCard(state),
                const SizedBox(height: 16),

                // --- Server URL ---
                _buildServerUrlCard(state),
                const SizedBox(height: 16),

                // --- Store Info ---
                if (state.isSetup) _buildStoreInfoCard(state),

                if (state.isSetup) ...[
                  const SizedBox(height: 16),
                  _buildDangerZone(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(ServerConnectionState state) {
    IconData icon;
    Color color;
    String text;

    switch (state.status) {
      case ConnectionStatus.connected:
        icon = Icons.cloud_done;
        color = OceanTheme.oceanPrimary;
        text = 'Đã kết nối — ${state.storeName ?? 'Cửa hàng'}';
        break;
      case ConnectionStatus.loading:
        icon = Icons.hourglass_top;
        color = Colors.grey;
        text = 'Đang xử lý...';
        break;
      case ConnectionStatus.error:
        icon = Icons.cloud_off;
        color = Colors.red;
        text = state.error ?? 'Lỗi kết nối';
        break;
      case ConnectionStatus.needsSetup:
        icon = Icons.cloud_off_outlined;
        color = Colors.grey;
        text = 'Chưa thiết lập cửa hàng';
        break;
      default:
        icon = Icons.cloud_off_outlined;
        color = Colors.grey;
        text = 'Đang khởi tạo...';
    }

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: state.storeId != null
            ? Text(
                'Store ID: ${state.storeId!.substring(0, 8)}...',
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.outline),
              )
            : null,
      ),
    );
  }

  Widget _buildServerUrlCard(ServerConnectionState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Địa chỉ Server',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                hintText: 'http://localhost:3000',
                prefixIcon: const Icon(Icons.dns_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: () {
                    context.read<ConnectionBloc>().add(
                        ServerUrlChanged(_serverUrlController.text.trim()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu địa chỉ server')),
                    );
                  },
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoCard(ServerConnectionState state) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.store_rounded),
            title: Text(state.storeName ?? 'Cửa hàng'),
            subtitle: Text('ID: ${state.storeId ?? 'N/A'}'),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.warning_rounded,
                color: Theme.of(context).colorScheme.error),
            title: Text('Đặt lại ứng dụng',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text('Xóa thiết lập và bắt đầu lại'),
            onTap: () => _confirmReset(),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt lại ứng dụng?'),
        content: const Text(
            'Thao tác này sẽ xóa thiết lập kết nối. Dữ liệu trên server không bị mất.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ConnectionBloc>()
                  .add(const ConnectionResetRequested());
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }
}
