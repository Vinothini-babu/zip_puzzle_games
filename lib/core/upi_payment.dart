import 'package:url_launcher/url_launcher.dart';

/// Opens a real UPI payment intent (GPay / PhonePe / Paytm / any UPI
/// app installed on the device) with the amount pre-filled, exactly
/// like real shopping apps do.
///
/// IMPORTANT — read before you ship this for real money:
/// - [upiId] below is a placeholder. Replace it with your own UPI ID
///   (from your bank, or a payment aggregator like Razorpay/Cashfree).
/// - This only OPENS the payment app. It cannot know whether the
///   payment actually succeeded — a user could open GPay, cancel, and
///   come back. Crediting coins the moment they return (as this demo
///   does) is NOT safe for real money; a production app needs a
///   backend that verifies the payment (via the aggregator's webhook /
///   order-status API) before crediting anything.
/// - On an emulator this will usually fail (no UPI app installed) —
///   [launchUpiPayment] returns false in that case.
class UpiPayment {
  static const String upiId = 'yourupiid@okhdfcbank'; // <-- replace this
  static const String payeeName = 'ZIP Puzzle';

  /// Returns true if a UPI app was actually opened.
  static Future<bool> launch({required num amountRupees, required String note}) async {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': payeeName,
        'am': amountRupees.toStringAsFixed(2),
        'cu': 'INR',
        'tn': note,
      },
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}