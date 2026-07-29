import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';

class PaymentService {
  late Razorpay _razorpay;
  final PaymentRepository _repo;

  PaymentService(this._repo) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Call verifyPayment
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle error
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle wallet
  }

  Future<void> startPayment(String planId, String serverName) async {
    final order = await _repo.createOrder(planId, serverName);
    var options = {
      'key': 'rzp_test_xxxx',
      'amount': (order.amount * 100).toInt(),
      'name': 'RenCloud',
      'order_id': order.razorpayOrderId,
    };
    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}

final paymentServiceProvider = Provider((ref) => PaymentService(PaymentRepository()));
