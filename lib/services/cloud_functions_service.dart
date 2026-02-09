import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionsService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send OTP via email using Cloud Function
  static Future<bool> sendOtpEmail({
    required String email,
    required String otp,
    required String username,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendOtpEmail');

      final response = await callable.call({
        'email': email,
        'otp': otp,
        'username': username,
      });

      // CloudFunctions return true if successful
      return response.data['success'] ?? false;
    } catch (e) {
      print('Error sending OTP email: $e');
      rethrow;
    }
  }

  /// Send welcome email after successful registration
  static Future<bool> sendWelcomeEmail({
    required String email,
    required String username,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendWelcomeEmail');

      final response = await callable.call({
        'email': email,
        'username': username,
      });

      return response.data['success'] ?? false;
    } catch (e) {
      print('Error sending welcome email: $e');
      rethrow;
    }
  }

  /// Send resend OTP email
  static Future<bool> resendOtpEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendOtpEmail');

      final response = await callable.call({
        'email': email,
        'otp': otp,
        'username': 'User',
        'isResend': true,
      });

      return response.data['success'] ?? false;
    } catch (e) {
      print('Error resending OTP email: $e');
      rethrow;
    }
  }
}
