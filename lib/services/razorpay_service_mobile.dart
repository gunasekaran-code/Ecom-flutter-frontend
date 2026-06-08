import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  Razorpay? _razorpay;
  void Function(String paymentId)? _onSuccess;
  void Function(String message, bool isCancelled)? _onError;

  void init({
    required void Function(String paymentId) onSuccess,
    required void Function(String message, bool isCancelled) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) {
      _onSuccess?.call(response.paymentId ?? '');
    });
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      final cancelled = response.code == Razorpay.PAYMENT_CANCELLED;
      _onError?.call(response.message ?? 'Payment failed', cancelled);
    });
    _razorpay!.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      (ExternalWalletResponse response) {},
    );
  }

  void open(Map<String, dynamic> options) {
    _razorpay?.open(options);
  }

  void clear() {
    _razorpay?.clear();
  }
}
