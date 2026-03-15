/// Category management page with list and add/edit dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/presentation/shared/animated_refresh_button.dart';

import 'package:fishcash_pos/domain/models/category_model.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_bloc.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_event_state.dart';
import 'package:fishcash_pos/core/utils/validators.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
        actions: [
          AnimatedRefreshButton(
            onPressed: () {
              context
                  .read<CategoryBloc>()
                  .add(const CategoriesLoadRequested());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state.status == CategoryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CategoryStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đã xảy ra lỗi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(state.errorMessage ?? ''),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context
                          .read<CategoryBloc>()
                          .add(const CategoriesLoadRequested());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có danh mục nào',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút "+" để thêm danh mục đầu tiên',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return _CategoryListTile(
                category: category,
                onEdit: () => _showFormDialog(context, category: category),
                onToggle: () {
                  context.read<CategoryBloc>().add(
                        CategoryToggleRequested(
                          id: category.id,
                          isActive: !category.isActive,
                        ),
                      );
                },
                onDelete: () => _confirmDelete(context, category),
              );
            },
          );
        },
      ),
    );
  }

  void _showFormDialog(BuildContext context, {CategoryModel? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController =
        TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Sửa danh mục' : 'Thêm danh mục'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục *',
                    hintText: 'VD: Cá, Tôm, Mực...',
                    prefixIcon: Icon(Icons.category),
                  ),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên danh mục';
                    }
                    if (AppValidators.startsWithSymbol(value)) {
                      return 'Tên không được bắt đầu bằng ký hiệu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Mô tả ngắn về danh mục...',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (isEditing) {
                  context.read<CategoryBloc>().add(
                        CategoryUpdateRequested(
                          id: category.id,
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                        ),
                      );
                } else {
                  context.read<CategoryBloc>().add(
                        CategoryCreateRequested(
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                        ),
                      );
                }
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
          size: 40,
        ),
        title: const Text('Xóa danh mục?'),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.name}"?\nCác sản phẩm thuộc danh mục này sẽ bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context
                  .read<CategoryBloc>()
                  .add(CategoryDeleteRequested(category.id));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

/// Individual category list item
class _CategoryListTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CategoryListTile({
    required this.category,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.category,
            color: category.isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration:
                category.isActive ? null : TextDecoration.lineThrough,
            color: category.isActive
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: category.description.isNotEmpty
            ? Text(
                category.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle visibility
            IconButton(
              icon: Icon(
                category.isActive
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: category.isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              tooltip: category.isActive ? 'Ẩn' : 'Hiện',
              onPressed: onToggle,
            ),
            // Edit
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
              tooltip: 'Sửa',
              onPressed: onEdit,
            ),
            // Delete
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Xóa',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
