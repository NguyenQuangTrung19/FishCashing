/// Connection Settings Page — server info and connectivity status.
///
/// Replaces the old SyncSettingsPage. Shows connection status,
/// server URL config, and store info. No login/register form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/presentation/sync/bloc/sync_bloc.dart';
import 'package:fishcash_pos/presentation/settings/bloc/store_info_bloc.dart';

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
                  _buildSyncCard(state),
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
        // Use store name from StoreInfoBloc (editable in Settings)
        final storeInfoState = context.watch<StoreInfoBloc>().state;
        final infoName = storeInfoState.storeInfo?.name ?? '';
        final displayName = infoName.isNotEmpty
            ? infoName
            : (state.storeName ?? 'Cửa hàng');
        text = 'Đã kết nối — $displayName';
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
    return BlocBuilder<StoreInfoBloc, StoreInfoState>(
      builder: (context, storeState) {
        final infoName = storeState.storeInfo?.name ?? '';
        final displayName = infoName.isNotEmpty
            ? infoName
            : (state.storeName ?? 'Cửa hàng');
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.store_rounded),
                title: Text(displayName),
                subtitle: Text('ID: ${state.storeId ?? 'N/A'}'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncCard(ServerConnectionState state) {
    final isSyncing = state.syncStatus == DataSyncStatus.syncing;

    String syncStatusText;
    IconData syncIcon;
    Color syncColor;

    switch (state.syncStatus) {
      case DataSyncStatus.syncing:
        syncStatusText = 'Đang đồng bộ...';
        syncIcon = Icons.sync_rounded;
        syncColor = Colors.blue;
      case DataSyncStatus.success:
        syncStatusText = 'Đồng bộ thành công';
        syncIcon = Icons.sync_rounded;
        syncColor = Colors.green;
      case DataSyncStatus.error:
        syncStatusText = state.syncError ?? 'Lỗi đồng bộ';
        syncIcon = Icons.sync_problem_rounded;
        syncColor = Colors.red;
      default:
        syncStatusText = 'Chưa đồng bộ';
        syncIcon = Icons.sync_disabled_rounded;
        syncColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(syncIcon, color: syncColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đồng bộ dữ liệu',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              syncStatusText,
              style: TextStyle(color: syncColor, fontSize: 13),
            ),
            if (state.lastSyncAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Lần sync cuối: ${_formatSyncTime(state.lastSyncAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            if (state.syncStatus == DataSyncStatus.success) ...[
              const SizedBox(height: 4),
              Text(
                '↑ ${state.lastPushed} đẩy lên · ↓ ${state.lastPulled} kéo về',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSyncing
                    ? null
                    : () {
                        context
                            .read<ConnectionBloc>()
                            .add(const SyncRequested());
                      },
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Đồng bộ ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
