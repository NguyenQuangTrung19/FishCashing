/// Order Creation View — POS-like UI for creating buy/sell orders within a session.
///
/// Reuses the product grid + cart pattern from POS page,
/// but creates trade orders linked to a trading session.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:decimal/decimal.dart';

import 'package:fishcash_pos/core/constants/app_constants.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';
import 'package:fishcash_pos/core/utils/formatters.dart';
import 'package:fishcash_pos/core/utils/currency_input_formatter.dart';
import 'package:fishcash_pos/core/utils/unit_converter.dart';
import 'package:fishcash_pos/domain/models/cart_model.dart';
import 'package:fishcash_pos/domain/models/product_model.dart';
import 'package:fishcash_pos/presentation/shared/widgets/store_logo.dart';

import 'package:fishcash_pos/presentation/pos/bloc/pos_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_bloc.dart';
import 'package:fishcash_pos/presentation/products/bloc/product_event_state.dart';


/// Full-screen view for creating or editing an order (buy or sell) within a session.
class OrderCreationView extends StatelessWidget {
  final String sessionId;
  final String orderType; // 'buy' or 'sell'
  final String? partnerId;
  final String? partnerName;
  final String? editingOrderId; // non-null = editing existing order
  final VoidCallback onDone;
  final VoidCallback onCancel;

  const OrderCreationView({
    super.key,
    required this.sessionId,
    required this.orderType,
    this.partnerId,
    this.partnerName,
    this.editingOrderId,
    required this.onDone,
    required this.onCancel,
  });

  bool get isBuy => orderType == 'buy';
  bool get isEditing => editingOrderId != null;

  Color get accentColor => isBuy ? OceanTheme.buyBlue : OceanTheme.sellGreen;

  String get title {
    if (isEditing) {
      return isBuy ? '✏️ Chỉnh sửa đơn MUA VÀO' : '✏️ Chỉnh sửa đơn BÁN RA';
    }
    return isBuy ? '🔴 Tạo đơn MUA VÀO' : '🟢 Tạo đơn BÁN RA';
  }

  String get partnerLabel => isBuy ? 'Nhà cung cấp' : 'Khách mua';

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listener: (context, state) {
        if (state.status == PosStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isBuy ? "Đơn mua" : "Đơn bán"} đã tạo thành công!'),
              backgroundColor: accentColor,
            ),
          );
          onDone();
        } else if (state.status == PosStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              context.read<PosBloc>().add(const PosClearCart());
              onCancel();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 16)),
              if (partnerName != null)
                Text(
                  '${isBuy ? "🚢" : "🏪"} $partnerName',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          actions: [
            BlocBuilder<PosBloc, PosState>(
              builder: (context, state) {
                return _UnitToggleButton(displayUnit: state.cart.displayUnit);
              },
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return _DesktopLayout(
                accentColor: accentColor,
                isBuy: isBuy,
                partnerId: partnerId,
              );
            }
            return _MobileLayout(
              accentColor: accentColor,
              isBuy: isBuy,
              partnerId: partnerId,
            );
          },
        ),
      ),
    );
  }
}

/// Desktop: products left + cart right
class _DesktopLayout extends StatelessWidget {
  final Color accentColor;
  final bool isBuy;
  final String? partnerId;

  const _DesktopLayout({
    required this.accentColor,
    required this.isBuy,
    this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _ProductGrid()),
        SizedBox(
          width: 400,
          child: _CartPanel(
            accentColor: accentColor,
            isBuy: isBuy,
            partnerId: partnerId,
          ),
        ),
      ],
    );
  }
}

/// Mobile: products + bottom cart bar
class _MobileLayout extends StatelessWidget {
  final Color accentColor;
  final bool isBuy;
  final String? partnerId;

  const _MobileLayout({
    required this.accentColor,
    required this.isBuy,
    this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _ProductGrid()),
        BlocBuilder<PosBloc, PosState>(
          builder: (context, state) {
            if (state.cart.isEmpty) return const SizedBox.shrink();
            return _MobileCartBar(
              accentColor: accentColor,
              isBuy: isBuy,
              partnerId: partnerId,
            );
          },
        ),
      ],
    );
  }
}

/// Unit toggle kg ↔ tấn
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
        style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
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
        final activeProducts = state.products.where((p) => p.isActive).toList();

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
                return _ProductCard(product: activeProducts[index]);
              },
            );
          },
        );
      },
    );
  }
}

/// Product card — tap to add to cart
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showAddDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    OceanTheme.oceanLight.withValues(alpha: 0.2),
                    OceanTheme.oceanFoam.withValues(alpha: 0.3),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const StoreLogo(width: 144, fit: BoxFit.contain),
              ),
              const SizedBox(height: 8),
              Text(product.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${AppFormatters.currency(product.price)}/${product.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final qtyController = TextEditingController(text: '1');
    // Format initial price with dots
    final initialPrice = CurrencyInputFormatter.format(product.price.toDouble());
    final priceController = TextEditingController(text: initialPrice);
    String unit = product.unit;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Thêm ${product.name}'),
          content: SizedBox(
            width: 380,
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                  // Unit selector — auto-converts price when changed
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    items: UnitConstants.allUnits.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(UnitConstants.label(u)),
                      );
                    }).toList(),
                    onChanged: (newUnit) {
                      if (newUnit == null || newUnit == unit) return;

                      // Auto-convert price when unit changes
                      final rawPrice = CurrencyInputFormatter.parseToRaw(priceController.text);
                      if (rawPrice.isNotEmpty) {
                        final currentPrice = Decimal.parse(rawPrice);
                        final convertedPrice = UnitConverter.convertPrice(
                          currentPrice, unit, newUnit,
                        );
                        if (convertedPrice != null) {
                          priceController.text = CurrencyInputFormatter.format(
                            convertedPrice.toDouble(),
                          );
                        }
                      }

                      setState(() {
                        unit = newUnit;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Price with currency formatter
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Đơn giá (đ/$unit)',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'đ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập giá';
                      final raw = CurrencyInputFormatter.parseToRaw(v);
                      try {
                        final price = Decimal.parse(raw);
                        if (price <= Decimal.zero) return 'Giá phải > 0';
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
                  final rawPrice = CurrencyInputFormatter.parseToRaw(
                    priceController.text,
                  );
                  context.read<PosBloc>().add(PosAddToCart(
                    product: product,
                    quantity: Decimal.parse(qtyController.text),
                    unit: unit,
                    unitPrice: Decimal.parse(rawPrice),
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
  final Color accentColor;
  final bool isBuy;
  final String? partnerId;

  const _CartPanel({
    required this.accentColor,
    required this.isBuy,
    this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                ),
                child: Row(
                  children: [
                    Icon(isBuy ? Icons.shopping_cart : Icons.storefront,
                        color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${state.orderTypeLabel} (${state.cart.itemCount})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700, color: accentColor),
                      ),
                    ),
                    if (!state.cart.isEmpty)
                      TextButton.icon(
                        onPressed: () {
                          context.read<PosBloc>().add(const PosClearCart());
                        },
                        icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                        label: Text('Xóa', style: TextStyle(color: colorScheme.error)),
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
                            Icon(Icons.shopping_cart_outlined, size: 48,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            Text('Chọn sản phẩm để thêm',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.cart.items.length,
                        separatorBuilder: (c, i) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final item = state.cart.items[index];
                          return _CartItemTile(
                            item: item,
                            accentColor: accentColor,
                            onRemove: () {
                              context.read<PosBloc>().add(PosRemoveFromCart(index));
                            },
                          );
                        },
                      ),
              ),

              // Footer: total + confirm
              if (!state.cart.isEmpty) ...[
                const Divider(height: 1),
                _CheckoutFooter(
                  state: state,
                  accentColor: accentColor,
                  isBuy: isBuy,
                  partnerId: partnerId,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Cart item row
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final Color accentColor;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.accentColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(item.productName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${AppFormatters.quantity(item.quantity)} ${item.unit} × ${AppFormatters.currency(item.unitPrice)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppFormatters.currency(item.lineTotal),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: accentColor)),
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

/// Checkout footer with total and confirm button (partner pre-selected)
class _CheckoutFooter extends StatelessWidget {
  final PosState state;
  final Color accentColor;
  final bool isBuy;
  final String? partnerId;

  const _CheckoutFooter({
    required this.state,
    required this.accentColor,
    required this.isBuy,
    this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: state.status == PosStatus.processing
                  ? null
                  : () {
                      context.read<PosBloc>().add(PosCheckout(
                        partnerId: partnerId,
                      ));
                    },
              icon: state.status == PosStatus.processing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(isBuy ? Icons.shopping_cart_checkout : Icons.sell),
              label: Text(
                isBuy ? 'Xác nhận MUA VÀO' : 'Xác nhận BÁN RA',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile cart bar
class _MobileCartBar extends StatelessWidget {
  final Color accentColor;
  final bool isBuy;
  final String? partnerId;

  const _MobileCartBar({
    required this.accentColor,
    required this.isBuy,
    this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8, offset: const Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Badge(
                  label: Text('${state.cart.itemCount}'),
                  child: Icon(
                    isBuy ? Icons.shopping_cart : Icons.storefront,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppFormatters.currency(state.cart.total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, color: accentColor),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accentColor),
                  onPressed: () {
                    context.read<PosBloc>().add(const PosCheckout());
                  },
                  icon: Icon(isBuy ? Icons.shopping_cart_checkout : Icons.sell),
                  label: Text(isBuy ? 'Mua vào' : 'Bán ra'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
