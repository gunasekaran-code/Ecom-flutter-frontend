// ignore: avoid_web_libraries_in_flutter
import 'dart:js';

class RazorpayService {
  void Function(String paymentId)? _onSuccess;
  void Function(String message, bool isCancelled)? _onError;

  void init({
    required void Function(String paymentId) onSuccess,
    required void Function(String message, bool isCancelled) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
  }

  void open(Map<String, dynamic> options) {
    final checkoutCtor = context['Razorpay'];
    if (checkoutCtor == null) {
      _onError?.call('Razorpay checkout script is not loaded.', false);
      return;
    }

    final jsOptionsMap = Map<String, dynamic>.from(options)
      ..putIfAbsent('currency', () => 'INR')
      ..putIfAbsent('name', () => '')
      ..putIfAbsent('description', () => '')
      ..putIfAbsent('theme', () => <String, dynamic>{})
      ..putIfAbsent('prefill', () => <String, dynamic>{})
      ..['handler'] = (dynamic response) {
        final paymentId = response['razorpay_payment_id']?.toString() ?? '';
        _onSuccess?.call(paymentId);
      }
      ..['modal'] = <String, dynamic>{
        'ondismiss': () {
          _onError?.call('Payment cancelled', true);
        },
      };

    final jsOptions = JsObject.jsify(jsOptionsMap);

    try {
      final rzp = JsObject(checkoutCtor as JsFunction, [jsOptions]);
      rzp.callMethod('open');
    } catch (e) {
      _onError?.call('Could not open payment gateway: $e', false);
    }
  }

  void clear() {}
}
