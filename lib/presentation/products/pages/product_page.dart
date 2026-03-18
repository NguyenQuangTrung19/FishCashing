/// Product management page with grid view and add/edit dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fishcash_pos/presentation/shared/animated_refresh_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';

import 'package:fishcash_pos/core/constants/app_constants.dart';
import 'package:fishcash_pos/core/utils/currency_input_formatter.dart';
import 'package:fishcash_pos/core/utils/validators.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/presentation/shared/widgets/store_logo.dart';
import 'package:fishcash_pos/domain/models/product_model.dart';
import 'package:fishcash_pos/presentation/categories/bloc/category_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_event_state.dart';
import 'package:fishcash_pos/presentation/shared/widgets/search_filter_bar.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String _searchQuery = '';
  String _categoryFilter = 'all'; // 'all' or categoryId
  String _activeFilter = 'active'; // 'all', 'active', 'inactive'

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    var filtered = products;

    // Active filter
    if (_activeFilter == 'active') {
      filtered = filtered.where((p) => p.isActive).toList();
    } else if (_activeFilter == 'inactive') {
      filtered = filtered.where((p) => !p.isActive).toList();
    }

    // Category filter
    if (_categoryFilter != 'all') {
      filtered =
          filtered.where((p) => p.categoryId == _categoryFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sản phẩm'),
        actions: [
          AnimatedRefreshButton(
            onPressed: () {
              context.read<ProductBloc>().add(const ProductsLoadRequested());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state.status == ProductStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ProductStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Đã xảy ra lỗi',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(state.errorMessage ?? ''),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context
                          .read<ProductBloc>()
                          .add(const ProductsLoadRequested());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có sản phẩm nào',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút "+" để thêm sản phẩm đầu tiên',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          // Build category filter options
          final categoryState = context.watch<CategoryBloc>().state;
          final categoryFilters = [
            const FilterOption(
                id: 'all', label: 'Tất cả', icon: Icons.apps),
            ...categoryState.categories
                .where((c) => c.isActive)
                .map((c) => FilterOption(
                      id: c.id,
                      label: c.name,
                      icon: Icons.category,
                    )),
          ];

          final filtered = _applyFilters(state.products);

          return Column(
            children: [
              // Search bar + category chips
              SearchFilterBar(
                hintText: 'Tìm sản phẩm...',
                onSearchChanged: (q) => setState(() => _searchQuery = q),
                filters: categoryFilters,
                selectedFilterId: _categoryFilter,
                onFilterChanged: (id) =>
                    setState(() => _categoryFilter = id),
              ),
              // Active/inactive toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _StatusChip(
                      label: 'Đang bán',
                      count: state.products.where((p) => p.isActive).length,
                      isSelected: _activeFilter == 'active',
                      color: OceanTheme.sellGreen,
                      onTap: () =>
                          setState(() => _activeFilter = 'active'),
                    ),
                    const SizedBox(width: 6),
                    _StatusChip(
                      label: 'Đã ẩn',
                      count:
                          state.products.where((p) => !p.isActive).length,
                      isSelected: _activeFilter == 'inactive',
                      color: OceanTheme.warningAmber,
                      onTap: () =>
                          setState(() => _activeFilter = 'inactive'),
                    ),
                    const SizedBox(width: 6),
                    _StatusChip(
                      label: 'Tất cả',
                      count: state.products.length,
                      isSelected: _activeFilter == 'all',
                      color: OceanTheme.oceanPrimary,
                      onTap: () =>
                          setState(() => _activeFilter = 'all'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('Không tìm thấy sản phẩm',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 900
                              ? 5
                              : (constraints.maxWidth > 600 ? 4 : 3);
                          return GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 88),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              return _ProductCard(
                                product: product,
                                onEdit: () =>
                                    _showFormDialog(context, product: product),
                                onToggle: () {
                                  context.read<ProductBloc>().add(
                                        ProductToggleRequested(
                                          id: product.id,
                                          isActive: !product.isActive,
                                        ),
                                      );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFormDialog(BuildContext context, {ProductModel? product}) {
    final isEditing = product != null;
    final nameController =
        TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null
          ? CurrencyInputFormatter.format(product.price.toDouble())
          : '',
    );
    String selectedUnit = product?.unit ?? 'kg';
    String? selectedCategoryId = product?.categoryId;
    final formKey = GlobalKey<FormState>();

    // Get categories from BLoC
    final categoryState = context.read<CategoryBloc>().state;
    final categories = categoryState.categories
        .where((c) => c.isActive)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      hintText: 'VD: Cá Thu, Tôm Sú...',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên sản phẩm';
                      }
                      if (AppValidators.startsWithSymbol(value)) {
                        return 'Tên không được bắt đầu bằng ký hiệu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategoryId = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn danh mục';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price and Unit row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Đơn giá (đ) *',
                            hintText: '150.000',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nhập giá';
                            }
                            try {
                              final raw = CurrencyInputFormatter.parseToRaw(value);
                              final price = Decimal.parse(raw);
                              if (price < Decimal.zero) return 'Giá không hợp lệ';
                            } catch (_) {
                              return 'Giá không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Đơn vị',
                          ),
                          items: UnitConstants.allUnits.map((u) {
                            return DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUnit = value ?? 'kg';
                            });
                          },
                        ),
                      ),
                    ],
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
                  final price = Decimal.parse(CurrencyInputFormatter.parseToRaw(priceController.text.trim()));

                  if (isEditing) {
                    dialogContext.read<ProductBloc>().add(
                          ProductUpdateRequested(
                            id: product.id,
                            name: nameController.text.trim(),
                            categoryId: selectedCategoryId!,
                            price: price,
                            unit: selectedUnit,
                          ),
                        );
                  } else {
                    dialogContext.read<ProductBloc>().add(
                          ProductCreateRequested(
                            name: nameController.text.trim(),
                            categoryId: selectedCategoryId!,
                            price: price,
                            unit: selectedUnit,
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
      ),
    );
  }
}

/// Product card for grid view
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product icon/image placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: product.isActive
                          ? [
                              OceanTheme.oceanLight.withValues(alpha: 0.2),
                              OceanTheme.oceanFoam.withValues(alpha: 0.3),
                            ]
                          : [
                              colorScheme.surfaceContainerHighest,
                              colorScheme.surfaceContainerHigh,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: StoreLogo(
                    width: 156,
                    fit: BoxFit.contain,
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Product name
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: product.isActive
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Category
              Text(
                product.categoryName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
              ),
              const SizedBox(height: 4),

              // Price and actions row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppFormatters.currency(product.price)}/${product.unit}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: OceanTheme.oceanPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        product.isActive
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                        color: product.isActive
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
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

/// Status chip for active/inactive filter
class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
