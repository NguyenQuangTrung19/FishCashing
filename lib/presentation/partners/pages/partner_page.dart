/// Partner management page with TabBar (Suppliers / Buyers) + CRUD dialogs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/presentation/shared/animated_refresh_button.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/validators.dart';
import 'package:fishcash_pos/domain/models/partner_model.dart';
import 'package:fishcash_pos/presentation/partners/bloc/partner_bloc.dart';

class PartnerPage extends StatelessWidget {
  const PartnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Đối tác'),
          actions: [
            AnimatedRefreshButton(
              onPressed: () {
                context
                    .read<PartnerBloc>()
                    .add(const PartnersLoadRequested());
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_boat), text: 'Nhà cung cấp'),
              Tab(icon: Icon(Icons.store), text: 'Khách mua'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () => _showFormDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm đối tác'),
            );
          },
        ),
        body: BlocBuilder<PartnerBloc, PartnerState>(
          builder: (context, state) {
            if (state.status == PartnerStatus.loading &&
                state.partners.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _PartnerList(
                  partners: state.suppliers,
                  emptyIcon: Icons.directions_boat_outlined,
                  emptyMessage: 'Chưa có nhà cung cấp',
                  emptyDescription:
                      'Thêm nhà cung cấp (chủ ghe, tàu cá, đầu mối)',
                ),
                _PartnerList(
                  partners: state.buyers,
                  emptyIcon: Icons.store_outlined,
                  emptyMessage: 'Chưa có khách mua',
                  emptyDescription:
                      'Thêm khách mua (nhà hàng, quán ăn, cơ sở chế biến)',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFormDialog(BuildContext context, {PartnerModel? partner}) {
    final isEditing = partner != null;
    final nameCtrl = TextEditingController(text: partner?.name ?? '');
    final phoneCtrl = TextEditingController(text: partner?.phone ?? '');
    final addressCtrl = TextEditingController(text: partner?.address ?? '');
    final noteCtrl = TextEditingController(text: partner?.note ?? '');
    PartnerType selectedType = partner?.type ?? PartnerType.supplier;
    final formKey = GlobalKey<FormState>();

    // Determine current tab to set default type
    final tabController = DefaultTabController.of(context);
    if (!isEditing && tabController.index == 1) {
      selectedType = PartnerType.buyer;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Sửa đối tác' : 'Thêm đối tác'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên đối tác *',
                        hintText: 'VD: Anh Tùng - Chủ ghe Phan Thiết',
                        prefixIcon: Icon(Icons.person),
                      ),
                      autofocus: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nhập tên đối tác';
                        }
                        if (AppValidators.startsWithSymbol(v)) {
                          return 'Tên không được bắt đầu bằng ký hiệu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type (only for new)
                    if (!isEditing)
                      SegmentedButton<PartnerType>(
                        segments: const [
                          ButtonSegment(
                            value: PartnerType.supplier,
                            label: Text('Nhà cung cấp'),
                            icon: Icon(Icons.directions_boat),
                          ),
                          ButtonSegment(
                            value: PartnerType.buyer,
                            label: Text('Khách mua'),
                            icon: Icon(Icons.store),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (s) =>
                            setState(() => selectedType = s.first),
                      ),
                    if (!isEditing) const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        hintText: '0901 234 567',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    // Address
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (isEditing) {
                    context.read<PartnerBloc>().add(PartnerUpdateRequested(
                          id: partner.id,
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          note: noteCtrl.text.trim(),
                        ));
                  } else {
                    context.read<PartnerBloc>().add(PartnerCreateRequested(
                          name: nameCtrl.text.trim(),
                          type: selectedType,
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          note: noteCtrl.text.trim(),
                        ));
                  }
                  Navigator.of(ctx).pop();
                }
              },
              child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Partner list widget (shared by supplier and buyer tabs)
class _PartnerList extends StatelessWidget {
  final List<PartnerModel> partners;
  final IconData emptyIcon;
  final String emptyMessage;
  final String emptyDescription;

  const _PartnerList({
    required this.partners,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.emptyDescription,
  });

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(emptyDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: partners.length,
      itemBuilder: (context, index) {
        final partner = partners[index];
        return _PartnerCard(partner: partner);
      },
    );
  }
}

/// Individual partner card
class _PartnerCard extends StatelessWidget {
  final PartnerModel partner;

  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSupplier = partner.type == PartnerType.supplier;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isSupplier ? OceanTheme.buyBlue : OceanTheme.sellGreen)
              .withValues(alpha: 0.15),
          child: Icon(
            isSupplier ? Icons.directions_boat : Icons.store,
            color: isSupplier ? OceanTheme.buyBlue : OceanTheme.sellGreen,
          ),
        ),
        title: Text(
          partner.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: partner.isActive ? null : TextDecoration.lineThrough,
            color: partner.isActive
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (partner.phone.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(partner.phone,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            if (partner.address.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(partner.address,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                partner.isActive ? Icons.visibility : Icons.visibility_off,
                color: partner.isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              tooltip: partner.isActive ? 'Ẩn' : 'Hiện',
              onPressed: () {
                context.read<PartnerBloc>().add(PartnerToggleRequested(
                    id: partner.id, isActive: !partner.isActive));
              },
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
              tooltip: 'Sửa',
              onPressed: () {
                _showEditDialog(context, partner: partner);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Xóa',
              onPressed: () => _confirmDelete(context, partner),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, {required PartnerModel partner}) {
    final nameCtrl = TextEditingController(text: partner.name);
    final phoneCtrl = TextEditingController(text: partner.phone);
    final addressCtrl = TextEditingController(text: partner.address);
    final noteCtrl = TextEditingController(text: partner.note);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa đối tác'),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên đối tác *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    autofocus: true,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nhập tên đối tác'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<PartnerBloc>().add(PartnerUpdateRequested(
                      id: partner.id,
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      note: noteCtrl.text.trim(),
                    ));
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PartnerModel partner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.error, size: 40),
        title: const Text('Xóa đối tác?'),
        content: Text('Bạn có chắc muốn xóa "${partner.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context
                  .read<PartnerBloc>()
                  .add(PartnerDeleteRequested(partner.id));
              Navigator.of(ctx).pop();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
