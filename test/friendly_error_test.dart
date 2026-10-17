import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_first_app_vsc/utils/friendly_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user messages pass through unchanged', () {
    expect(friendlyError(const UserMessage('Incorrect password.'), 'Ignored'), 'Incorrect password.');
  });

  test('offline errors point at the connection', () {
    expect(
      friendlyError(TimeoutException('x'), "Couldn't load your games"),
      "Couldn't load your games. Check your internet connection and try again.",
    );
    expect(
      friendlyError(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'), "Couldn't save"),
      "Couldn't save. Check your internet connection and try again.",
    );
  });

  test('raw details never reach the user', () {
    final msg = friendlyError(
      Exception('Failed to create default season: [cloud_firestore/internal] stack #0 foo.dart:12'),
      "Couldn't create the season",
    );
    expect(msg, "Couldn't create the season. Please try again.");
  });

  test('auth and function codes map to plain advice', () {
    expect(
      friendlyError(FirebaseAuthException(code: 'requires-recent-login'), "Couldn't change your password"),
      "Couldn't change your password. Please sign out and back in, then try again.",
    );
    expect(
      friendlyError(
        FirebaseFunctionsException(code: 'invalid-argument', message: 'That promo code has expired.'),
        "Couldn't apply that code",
      ),
      "Couldn't apply that code. That promo code has expired.",
    );
  });
}
