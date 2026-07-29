class CreateOrderResponse {
  final String orderId;
  final String razorpayOrderId;
  final double amount;
  
  CreateOrderResponse({required this.orderId, required this.razorpayOrderId, required this.amount});

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      orderId: json['order_id'] ?? '',
      razorpayOrderId: json['razorpay_order_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}
