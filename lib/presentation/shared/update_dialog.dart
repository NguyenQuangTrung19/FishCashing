import 'package:flutter/material.dart';
import 'package:fishcash_pos/core/services/app_updater.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';

/// Shows update dialog when a new version is available.
class UpdateDialog extends StatefulWidget {
  final AppUpdater updater;
  const UpdateDialog({super.key, required this.updater});

  /// Check for updates and show dialog if available.
  static Future<void> checkAndShow(BuildContext context) async {
    final updater = await AppUpdater.checkForUpdate();
    if (!updater.hasUpdate) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(updater: updater),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      await widget.updater.downloadAndInstall(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Cập nhật thất bại: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [OceanTheme.oceanPrimary, OceanTheme.oceanFoam],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.system_update, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Cập nhật mới'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phiên bản ${widget.updater.latestVersion} đã sẵn sàng!',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (widget.updater.releaseNotes != null &&
                widget.updater.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.updater.releaseNotes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
            if (_downloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đang tải: ${(_progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        if (!_downloading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Để sau'),
          ),
          FilledButton.icon(
            onPressed: _startUpdate,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Cập nhật ngay'),
          ),
        ] else
          const TextButton(
            onPressed: null,
            child: Text('Đang cập nhật...'),
          ),
      ],
    );
  }
}
