import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thrown with a message that is already written for the user.
class UserMessage implements Exception {
  final String message;
  const UserMessage(this.message);

  @override
  String toString() => message;
}

const _offline = 'Check your internet connection and try again.';
const _retry = 'Please try again.';

bool _looksOffline(String text) {
  final t = text.toLowerCase();
  return t.contains('network') ||
      t.contains('socket') ||
      t.contains('offline') ||
      t.contains('timed out') ||
      t.contains('timeout') ||
      t.contains('unavailable') ||
      t.contains('connection') ||
      t.contains('host lookup');
}

/// The part after [action] that tells the user what to do next.
String _hint(Object error) {
  if (error is TimeoutException) return _offline;

  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'network-request-failed' => _offline,
      'requires-recent-login' => 'Please sign out and back in, then try again.',
      'wrong-password' || 'invalid-credential' => 'Your current password is incorrect.',
      'weak-password' => 'Use a password with at least 6 characters.',
      'too-many-requests' => 'Too many attempts. Wait a few minutes and try again.',
      'user-disabled' => 'This account has been disabled. Please contact support.',
      _ => _retry,
    };
  }

  if (error is FirebaseFunctionsException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => _offline,
      'unauthenticated' => 'Please sign out and back in, then try again.',
      'resource-exhausted' => "You've hit the limit for now. Try again a little later.",
      'permission-denied' => "You don't have access to that.",
      // Server-side checks (bad promo code, missing info) send readable text.
      'invalid-argument' || 'failed-precondition' || 'not-found' || 'already-exists'
          when (error.message ?? '').isNotEmpty =>
        error.message!,
      _ => _retry,
    };
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' || 'retry-limit-exceeded' => _offline,
      'permission-denied' || 'unauthorized' => "You don't have access to that.",
      'unauthenticated' => 'Please sign out and back in, then try again.',
      'not-found' || 'object-not-found' => "It may have been deleted. Pull to refresh.",
      'quota-exceeded' || 'resource-exhausted' => 'The server is busy. Try again in a minute.',
      _ => _looksOffline('${error.message}') ? _offline : _retry,
    };
  }

  return _looksOffline(error.toString()) ? _offline : _retry;
}

/// A sentence safe to show users: "[action]. [what to do next]".
/// Never includes exception class names, codes, or stack text.
/// A [UserMessage] is returned as is.
String friendlyError(Object error, [String action = 'Something went wrong']) {
  if (error is UserMessage) return error.message;
  return '$action. ${_hint(error)}';
}
