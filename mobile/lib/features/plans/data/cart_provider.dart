import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'plan_models.dart';

class CartItem {
  final Plan plan;
  int quantity;

  CartItem({required this.plan, this.quantity = 1});

  double get subtotal => plan.priceMonthly * quantity;

  Map<String, dynamic> toJson() => {
    'plan_id': plan.id,
    'plan_name': plan.name,
    'plan_slug': plan.slug,
    'quantity': quantity,
    'subtotal': subtotal,
  };
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => state.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => state.isEmpty;

  void addToCart(Plan plan, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.plan.id == plan.id);
    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            CartItem(plan: plan, quantity: state[i].quantity + quantity)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(plan: plan, quantity: quantity)];
    }
  }

  void removeFromCart(String planId) {
    state = state.where((item) => item.plan.id != planId).toList();
  }

  void updateQuantity(String planId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(planId);
      return;
    }
    state = state.map((item) {
      if (item.plan.id == planId) {
        return CartItem(plan: item.plan, quantity: quantity);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalPriceProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, item) => sum + item.subtotal);
});
