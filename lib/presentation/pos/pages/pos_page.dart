/// POS Page — Point of Sale with product grid + cart.
///
/// Desktop: side-by-side layout (products left, cart right)
/// Mobile: bottom sheet cart with product grid
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';

import 'package:fishcash_pos/core/constants/app_constants.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/domain/models/cart_model.dart';
import 'package:fishcash_pos/domain/models/product_model.dart';
import 'package:fishcash_pos/presentation/pos/bloc/pos_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_event_state.dart';
import 'package:fishcash_pos/presentation/shared/widgets/store_logo.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listener: (context, state) {
        if (state.status == PosStatus.success) {
          _showSuccessDialog(context, state.lastOrderId ?? '');
        } else if (state.status == PosStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return _DesktopPosLayout();
          } else {
            return _MobilePosLayout();
          }
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: OceanTheme.sellGreen,
          size: 64,
        ),
        title: const Text('Thanh toán thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đơn hàng đã được tạo thành công',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Mã đơn: ${orderId.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

/// Desktop: products left (60%) + cart right (40%)
class _DesktopPosLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bán hàng (POS)'),
        actions: [
          BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              return _UnitToggleButton(displayUnit: state.cart.displayUnit);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Product grid
          Expanded(
            flex: 3,
            child: _ProductGrid(),
          ),
          // Cart panel
          SizedBox(
            width: 380,
            child: _CartPanel(),
          ),
        ],
      ),
    );
  }
}

/// Mobile: product grid with floating cart badge
class _MobilePosLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bán hàng (POS)'),
        actions: [
          BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              return _UnitToggleButton(displayUnit: state.cart.displayUnit);
            },
          ),
        ],
      ),
      body: _ProductGrid(),
      bottomSheet: BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          if (state.cart.isEmpty) return const SizedBox.shrink();
          return _MobileCartBar(cart: state);
        },
      ),
    );
  }
}

/// Unit toggle button (kg ↔ tấn)
class _UnitToggleButton extends StatelessWidget {
  final String displayUnit;

  const _UnitToggleButton({required this.displayUnit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'kg', label: Text('kg')),
          ButtonSegment(value: 'tấn', label: Text('tấn')),
        ],
        selected: {displayUnit},
        onSelectionChanged: (selected) {
          context.read<PosBloc>().add(PosSwitchUnit(selected.first));
        },
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// Product grid for selection
class _ProductGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final activeProducts =
            state.products.where((p) => p.isActive).toList();

        if (activeProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('Chưa có sản phẩm',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount =
                constraints.maxWidth > 600 ? 4 : (constraints.maxWidth > 400 ? 3 : 2);

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: activeProducts.length,
              itemBuilder: (context, index) {
                return _PosProductCard(product: activeProducts[index]);
              },
            );
          },
        );
      },
    );
  }
}

/// Product card in POS grid — tap to add to cart
class _PosProductCard extends StatelessWidget {
  final ProductModel product;

  const _PosProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => _showAddDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      OceanTheme.oceanLight.withValues(alpha: 0.2),
                      OceanTheme.oceanFoam.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const StoreLogo(
                  width: 144,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              // Name
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Price
              Text(
                '${AppFormatters.currency(product.price)}/${product.unit}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final qtyController = TextEditingController(text: '1');
    final priceController =
        TextEditingController(text: product.price.toString());
    String unit = product.unit;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Thêm ${product.name}'),
          content: SizedBox(
            width: 350,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quantity
                  TextFormField(
                    controller: qtyController,
                    decoration: InputDecoration(
                      labelText: 'Số lượng ($unit)',
                      prefixIcon: const Icon(Icons.straighten),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập số lượng';
                      try {
                        final qty = Decimal.parse(v);
                        if (qty <= Decimal.zero) return 'Phải > 0';
                      } catch (_) {
                        return 'Số không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Unit
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    items: UnitConstants.allUnits.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u));
                    }).toList(),
                    onChanged: (v) => setState(() => unit = v ?? product.unit),
                  ),
                  const SizedBox(height: 12),
                  // Price
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Đơn giá (đ/$unit)',
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập giá';
                      try {
                        Decimal.parse(v);
                      } catch (_) {
                        return 'Giá không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<PosBloc>().add(PosAddToCart(
                        product: product,
                        quantity: Decimal.parse(qtyController.text),
                        unit: unit,
                        unitPrice: Decimal.parse(priceController.text),
                      ));
                  Navigator.of(ctx).pop();
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Thêm vào giỏ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cart panel (desktop sidebar)
class _CartPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          return Column(
            children: [
              // Cart header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Giỏ hàng (${state.cart.itemCount})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    if (!state.cart.isEmpty)
                      TextButton.icon(
                        onPressed: () {
                          context.read<PosBloc>().add(const PosClearCart());
                        },
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: colorScheme.error),
                        label: Text('Xóa',
                            style: TextStyle(color: colorScheme.error)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Cart items
              Expanded(
                child: state.cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            Text(
                              'Giỏ hàng trống',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.cart.items.length,
                        separatorBuilder: (context2, idx) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final item = state.cart.items[index];
                          return _CartItemTile(
                            item: item,
                            onRemove: () {
                              context
                                  .read<PosBloc>()
                                  .add(PosRemoveFromCart(index));
                            },
                          );
                        },
                      ),
              ),

              // Total and checkout
              if (!state.cart.isEmpty) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng cộng:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            AppFormatters.currency(state.cart.total),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: OceanTheme.oceanPrimary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<PosBloc>().add(
                                    const PosCheckout(
                                        paymentMethod: 'qr_transfer'));
                              },
                              icon: const Icon(Icons.qr_code),
                              label: const Text('QR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: state.status == PosStatus.processing
                                  ? null
                                  : () {
                                      context.read<PosBloc>().add(
                                          const PosCheckout(
                                              paymentMethod: 'cash'));
                                    },
                              icon: state.status == PosStatus.processing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.payments),
                              label: const Text('Thanh toán'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Individual cart item row
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const _CartItemTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        item.productName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${AppFormatters.quantity(item.quantity)} ${item.unit} × ${AppFormatters.currency(item.unitPrice)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppFormatters.currency(item.lineTotal),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: OceanTheme.oceanPrimary,
                ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close,
                size: 18, color: Theme.of(context).colorScheme.error),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Mobile cart bar at bottom
class _MobileCartBar extends StatelessWidget {
  final PosState cart;

  const _MobileCartBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Badge(
              label: Text('${cart.cart.itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppFormatters.currency(cart.cart.total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: OceanTheme.oceanPrimary,
                    ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                context
                    .read<PosBloc>()
                    .add(const PosCheckout(paymentMethod: 'cash'));
              },
              icon: const Icon(Icons.payments),
              label: const Text('Thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}
