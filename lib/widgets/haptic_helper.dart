import 'package:flutter/services.dart';
import 'dart:io';

/// Utility class for providing haptic feedback across iOS and Android
class HapticHelper {
  /// Light impact haptic feedback
  /// Use for: Message sent, minor actions, button taps
  static Future<void> lightImpact() async {
    if (Platform.isIOS) {
      await HapticFeedback.lightImpact();
    } else if (Platform.isAndroid) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Medium impact haptic feedback
  /// Use for: Errors, important actions, confirmations
  static Future<void> mediumImpact() async {
    if (Platform.isIOS) {
      await HapticFeedback.mediumImpact();
    } else if (Platform.isAndroid) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Heavy impact haptic feedback
  /// Use for: Critical actions, completion, major events
  static Future<void> heavyImpact() async {
    if (Platform.isIOS) {
      await HapticFeedback.heavyImpact();
    } else if (Platform.isAndroid) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Selection feedback (subtle)
  /// Use for: List selections, option changes
  static Future<void> selection() async {
    if (Platform.isIOS) {
      await HapticFeedback.selectionClick();
    } else if (Platform.isAndroid) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Vibrate (Android only)
  /// Use for: Notifications, alerts
  static Future<void> vibrate({Duration? duration}) async {
    if (Platform.isAndroid) {
      await HapticFeedback.vibrate();
    }
  }
}

