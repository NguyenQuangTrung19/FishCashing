/// Sync Settings Page — Login, server config, and sync status.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/presentation/sync/bloc/sync_bloc.dart';

class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final _serverUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(const SyncInitRequested());
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state.status == SyncStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state.serverUrl != null &&
            _serverUrlController.text.isEmpty) {
          _serverUrlController.text = state.serverUrl!;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Đồng bộ & Sao lưu')),
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

                // --- Auth or Sync sections ---
                if (state.status == SyncStatus.loggedIn ||
                    state.status == SyncStatus.syncing)
                  _buildSyncSection(state)
                else
                  _buildAuthSection(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(SyncState state) {
    IconData icon;
    Color color;
    String text;

    switch (state.status) {
      case SyncStatus.loggedIn:
        icon = Icons.cloud_done;
        color = OceanTheme.oceanPrimary;
        text = 'Đã kết nối — ${state.userName ?? state.email}';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.amber;
        text = 'Đang đồng bộ...';
        break;
      case SyncStatus.loading:
        icon = Icons.hourglass_top;
        color = Colors.grey;
        text = 'Đang xử lý...';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = Colors.red;
        text = state.error ?? 'Lỗi kết nối';
        break;
      default:
        icon = Icons.cloud_off_outlined;
        color = Colors.grey;
        text = 'Chưa đăng nhập';
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
        subtitle: state.lastSyncAt != null
            ? Text(
                'Lần sync cuối: ${_formatDate(state.lastSyncAt!)}',
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.outline),
              )
            : null,
      ),
    );
  }

  Widget _buildServerUrlCard(SyncState state) {
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
                    context.read<SyncBloc>().add(
                        SyncServerUrlChanged(_serverUrlController.text.trim()));
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

  Widget _buildAuthSection(SyncState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle login/register
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false, label: Text('Đăng nhập')),
                      ButtonSegment(
                          value: true, label: Text('Đăng ký')),
                    ],
                    selected: {_isRegistering},
                    onSelectionChanged: (s) =>
                        setState(() => _isRegistering = s.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isRegistering) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: state.status == SyncStatus.loading
                  ? null
                  : () {
                      if (_isRegistering) {
                        context.read<SyncBloc>().add(SyncRegisterRequested(
                              _emailController.text.trim(),
                              _nameController.text.trim(),
                              _passwordController.text,
                            ));
                      } else {
                        context.read<SyncBloc>().add(SyncLoginRequested(
                              _emailController.text.trim(),
                              _passwordController.text,
                            ));
                      }
                    },
              icon: state.status == SyncStatus.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_isRegistering
                      ? Icons.person_add
                      : Icons.login),
              label: Text(_isRegistering ? 'Đăng ký' : 'Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection(SyncState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sync button
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Đồng bộ dữ liệu',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Đẩy dữ liệu local lên server và kéo dữ liệu mới từ các thiết bị khác về.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: state.status == SyncStatus.syncing
                      ? null
                      : () => context
                          .read<SyncBloc>()
                          .add(const SyncNowRequested()),
                  icon: state.status == SyncStatus.syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync_rounded),
                  label: Text(state.status == SyncStatus.syncing
                      ? 'Đang đồng bộ...'
                      : 'Đồng bộ ngay'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Account info
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(state.userName ?? 'User'),
                subtitle: Text(state.email ?? ''),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất',
                    style: TextStyle(color: Colors.red)),
                onTap: () => _confirmLogout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
            'Đăng xuất sẽ ngắt kết nối sync. Dữ liệu local không bị mất.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SyncBloc>().add(const SyncLogoutRequested());
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
