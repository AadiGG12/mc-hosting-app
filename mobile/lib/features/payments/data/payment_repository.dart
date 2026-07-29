import '../../../core/api_client.dart';
import 'payment_models.dart';

class PaymentRepository {
  Future<CreateOrderResponse> createOrder(String planId, String serverName) async {
    final res = await ApiClient.dio.post('/payments/create-order', data: {
      'plan_id': planId,
      'server_name': serverName,
    });
    return CreateOrderResponse.fromJson(res.data);
  }

  Future<void> verifyPayment(String orderId, String rzOrderId, String rzPaymentId, String rzSignature) async {
    await ApiClient.dio.post('/payments/verify', data: {
      'order_id': orderId,
      'razorpay_order_id': rzOrderId,
      'razorpay_payment_id': rzPaymentId,
      'razorpay_signature': rzSignature,
    });
  }
}
