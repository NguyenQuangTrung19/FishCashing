/// BLoC for Order Cart management.
///
/// Handles adding/removing products, unit conversion,
/// and checkout for both trade orders (buy/sell in sessions)
/// and standalone POS sales. Supports editing existing orders.
library;

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/data/repositories/trade_order_repository.dart';
import 'package:fishcash_pos/domain/models/cart_model.dart';
import 'package:fishcash_pos/domain/models/product_model.dart';

// === EVENTS ===

sealed class PosEvent extends Equatable {
  const PosEvent();
  @override
  List<Object?> get props => [];
}

/// Set the context for order creation (session + order type)
final class PosSetContext extends PosEvent {
  final String sessionId;
  final String orderType; // 'buy' or 'sell'

  const PosSetContext({
    required this.sessionId,
    required this.orderType,
  });

  @override
  List<Object?> get props => [sessionId, orderType];
}

/// Load existing order into cart for editing
final class PosLoadFromOrder extends PosEvent {
  final String orderId;
  final String sessionId;
  final String orderType;

  const PosLoadFromOrder({
    required this.orderId,
    required this.sessionId,
    required this.orderType,
  });

  @override
  List<Object?> get props => [orderId, sessionId, orderType];
}

/// Add a product to the cart
final class PosAddToCart extends PosEvent {
  final ProductModel product;
  final Decimal quantity;
  final String unit;
  final Decimal unitPrice;

  const PosAddToCart({
    required this.product,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  @override
  List<Object?> get props => [product.id, quantity, unit, unitPrice];
}

/// Remove item from cart by index
final class PosRemoveFromCart extends PosEvent {
  final int index;
  const PosRemoveFromCart(this.index);
  @override
  List<Object?> get props => [index];
}

/// Update quantity of cart item
final class PosUpdateQuantity extends PosEvent {
  final int index;
  final Decimal newQuantity;
  const PosUpdateQuantity(this.index, this.newQuantity);
  @override
  List<Object?> get props => [index, newQuantity];
}

/// Switch display unit for all items (kg ↔ tấn)
final class PosSwitchUnit extends PosEvent {
  final String newUnit;
  const PosSwitchUnit(this.newUnit);
  @override
  List<Object?> get props => [newUnit];
}

/// Clear the entire cart
final class PosClearCart extends PosEvent {
  const PosClearCart();
}

/// Checkout — create or update the order
final class PosCheckout extends PosEvent {
  final String paymentMethod; // 'cash' or 'qr_transfer'
  final String? partnerId;
  const PosCheckout({this.paymentMethod = 'cash', this.partnerId});
  @override
  List<Object?> get props => [paymentMethod, partnerId];
}

// === STATES ===

enum PosStatus { idle, loading, processing, success, error }

final class PosState extends Equatable {
  final Cart cart;
  final PosStatus status;
  final String? lastOrderId;
  final String? errorMessage;

  /// Context for trade orders (null = standalone POS)
  final String? sessionId;
  final String? orderType; // 'buy' or 'sell'

  /// Editing mode: non-null means editing an existing order
  final String? editingOrderId;

  const PosState({
    this.cart = const Cart(),
    this.status = PosStatus.idle,
    this.lastOrderId,
    this.errorMessage,
    this.sessionId,
    this.orderType,
    this.editingOrderId,
  });

  bool get isTradeOrder => sessionId != null;
  bool get isEditing => editingOrderId != null;
  bool get isBuyOrder => orderType == 'buy';
  bool get isSellOrder => orderType == 'sell';

  String get orderTypeLabel {
    switch (orderType) {
      case 'buy':
        return 'Đơn mua vào';
      case 'sell':
        return 'Đơn bán ra';
      default:
        return 'Bán hàng';
    }
  }

  PosState copyWith({
    Cart? cart,
    PosStatus? status,
    String? lastOrderId,
    String? errorMessage,
    String? sessionId,
    String? orderType,
    String? editingOrderId,
  }) {
    return PosState(
      cart: cart ?? this.cart,
      status: status ?? this.status,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      errorMessage: errorMessage,
      sessionId: sessionId ?? this.sessionId,
      orderType: orderType ?? this.orderType,
      editingOrderId: editingOrderId ?? this.editingOrderId,
    );
  }

  @override
  List<Object?> get props =>
      [cart, status, lastOrderId, errorMessage, sessionId, orderType, editingOrderId];
}

// === BLOC ===

class PosBloc extends Bloc<PosEvent, PosState> {
  final TradeOrderRepository _orderRepository;

  PosBloc(this._orderRepository) : super(const PosState()) {
    on<PosSetContext>(_onSetContext);
    on<PosLoadFromOrder>(_onLoadFromOrder);
    on<PosAddToCart>(_onAddToCart);
    on<PosRemoveFromCart>(_onRemoveFromCart);
    on<PosUpdateQuantity>(_onUpdateQuantity);
    on<PosSwitchUnit>(_onSwitchUnit);
    on<PosClearCart>(_onClearCart);
    on<PosCheckout>(_onCheckout);
  }

  void _onSetContext(PosSetContext event, Emitter<PosState> emit) {
    // Reset cart and set context for new order
    emit(PosState(
      sessionId: event.sessionId,
      orderType: event.orderType,
    ));
  }

  /// Load existing order items into cart for editing
  Future<void> _onLoadFromOrder(PosLoadFromOrder event, Emitter<PosState> emit) async {
    emit(PosState(
      status: PosStatus.loading,
      sessionId: event.sessionId,
      orderType: event.orderType,
      editingOrderId: event.orderId,
    ));

    try {
      final cart = await _orderRepository.loadCartFromOrder(event.orderId);
      emit(PosState(
        cart: cart,
        status: PosStatus.idle,
        sessionId: event.sessionId,
        orderType: event.orderType,
        editingOrderId: event.orderId,
      ));
    } catch (e) {
      emit(PosState(
        status: PosStatus.error,
        errorMessage: e.toString(),
        sessionId: event.sessionId,
        orderType: event.orderType,
        editingOrderId: event.orderId,
      ));
    }
  }

  void _onAddToCart(PosAddToCart event, Emitter<PosState> emit) {
    final cartItem = CartItem.fromProduct(
      product: event.product,
      quantity: event.quantity,
      unit: event.unit,
      unitPrice: event.unitPrice,
    );
    emit(state.copyWith(cart: state.cart.addItem(cartItem)));
  }

  void _onRemoveFromCart(PosRemoveFromCart event, Emitter<PosState> emit) {
    emit(state.copyWith(cart: state.cart.removeAt(event.index)));
  }

  void _onUpdateQuantity(PosUpdateQuantity event, Emitter<PosState> emit) {
    emit(state.copyWith(
      cart: state.cart.updateQuantityAt(event.index, event.newQuantity),
    ));
  }

  void _onSwitchUnit(PosSwitchUnit event, Emitter<PosState> emit) {
    emit(state.copyWith(cart: state.cart.convertAllTo(event.newUnit)));
  }

  void _onClearCart(PosClearCart event, Emitter<PosState> emit) {
    emit(state.copyWith(cart: state.cart.clear()));
  }

  Future<void> _onCheckout(PosCheckout event, Emitter<PosState> emit) async {
    if (state.cart.isEmpty) return;

    emit(state.copyWith(status: PosStatus.processing));

    try {
      String orderId;

      if (state.isEditing) {
        // Update existing order
        await _orderRepository.updateTradeOrder(
          orderId: state.editingOrderId!,
          cart: state.cart,
          sessionId: state.sessionId,
          note: '${state.orderTypeLabel} (chỉnh sửa)',
        );
        orderId = state.editingOrderId!;
      } else if (state.isTradeOrder) {
        // Create new trade order within session
        orderId = await _orderRepository.createTradeOrder(
          sessionId: state.sessionId!,
          partnerId: event.partnerId,
          orderType: state.orderType!,
          cart: state.cart,
          note: '${state.orderTypeLabel} - ${event.paymentMethod}',
        );
      } else {
        // Standalone POS order
        orderId = await _orderRepository.createPosOrder(
          cart: state.cart,
          paymentMethod: event.paymentMethod,
        );
      }

      emit(PosState(
        cart: const Cart(),
        status: PosStatus.success,
        lastOrderId: orderId,
        sessionId: state.sessionId,
        orderType: state.orderType,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PosStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
