import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Launch period: every signed-in user gets Pro. The server decides via FREE_PRO_FOR_ALL
/// (functions/.env), so the free period can end without an app update.
class TestLaunchService {
  TestLaunchService._();

  /// When true, the app calls [claimTestFlightPro] once per session on startup.
  static const bool freeProForTestLaunch = true;

  static bool _claimInFlight = false;
  static bool _claimedThisSession = false;

  /// Idempotent: sets users/{uid}.isProMode via Cloud Function.
  static Future<void> ensureTestFlightPro() async {
    if (!freeProForTestLaunch || _claimedThisSession || _claimInFlight) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _claimInFlight = true;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('claimTestFlightPro');
      final result = await callable.call().timeout(const Duration(seconds: 20));
      final data = result.data;
      if (data is Map && data['success'] == true) {
        _claimedThisSession = true;
        debugPrint('TestFlight Pro: ${data['message'] ?? 'activated'}');
      }
    } catch (e) {
      debugPrint('TestFlight Pro claim failed (will retry next launch): $e');
    } finally {
      _claimInFlight = false;
    }
  }
}
