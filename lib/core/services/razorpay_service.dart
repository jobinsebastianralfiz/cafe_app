import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Razorpay Service - Handles payment processing
class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentError;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Initialize payment
  Future<void> initiatePayment({
    required double amount,
    required String orderId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
  }) async {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;

    // Convert amount to paise (smallest currency unit)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': AppConfig.razorpayKeyId,
      'amount': amountInPaise,
      'name': 'Ralfiz Cafe',
      'description': 'Order Payment - $orderId',
      'order_id': orderId, // Generate order_id using Orders API in production
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName,
      },
      'theme': {
        'color': '#00BFA5', // AppColors.primary
      },
      'timeout': 300, // 5 minutes
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'send_sms_hash': true,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      rethrow;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');

    if (_onPaymentSuccess != null) {
      _onPaymentSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    if (_onPaymentError != null) {
      _onPaymentError!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  /// Clean up
  void dispose() {
    _razorpay.clear();
  }

  /// Verify payment signature (should be done on backend in production)
  /// This is a client-side verification for demo purposes
  bool verifySignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    // In production, this verification should be done on the backend
    // using Razorpay secret key
    // For now, we'll just return true as a placeholder
    debugPrint('Payment verification - Order: $orderId, Payment: $paymentId');
    return true;
  }
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorCode;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.errorMessage,
  });

  factory PaymentResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  factory PaymentResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return PaymentResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}
