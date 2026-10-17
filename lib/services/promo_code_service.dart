import 'package:cloud_functions/cloud_functions.dart';

/// Calls [redeemPromoCode] Cloud Function — unlocks Pro when a valid Firestore promo doc exists.
class PromoCodeService {
  PromoCodeService._();
  static final PromoCodeService instance = PromoCodeService._();

  FirebaseFunctions get _f => FirebaseFunctions.instance;

  /// Returns server message on success; throws [FirebaseFunctionsException] on failure.
  Future<String> redeem(String code) async {
    final trimmed = code.trim();
    if (trimmed.length < 3) {
      throw Exception('Enter a valid code.');
    }
    final callable = _f.httpsCallable('redeemPromoCode');
    final result = await callable.call({'code': trimmed});
    final raw = result.data;
    if (raw is Map) {
      final msg = raw['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Done.';
  }
}
