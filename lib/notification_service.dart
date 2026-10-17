import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:math';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  
  // Human-like, natural notification messages
  final List<String> _notificationMessages = [
    "Hey! How did your game go? Let's log those stats.",
    "Just checking in - ready to update your stats?",
    "How was practice today? Time to track your progress.",
    "Don't forget to log your latest game stats when you get a chance.",
    "Your stats are looking good! Want to add today's performance?",
    "Quick reminder: log your stats when you have a moment.",
    "How did you play today? Let's add it to your stats.",
    "Time to update your stats - how'd the game go?",
    "Your performance data is waiting. Ready to log it?",
    "Hey! Don't forget to log your stats from today's game.",
    "How was practice? Let's update your stats.",
    "Quick check-in: ready to log your latest stats?",
    "Your stats are calling - how'd you do today?",
    "Don't let today's performance slip away. Log it when you can.",
    "How was the game? Time to update your stats.",
  ];

  // Get random notification message
  String getRandomMessage() {
    final random = Random();
    return _notificationMessages[random.nextInt(_notificationMessages.length)];
  }

  Future<void> initialize() async {
    // Local notifications init (for foreground heads-up)
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _local.initialize(settings: initSettings);

    // Request permissions
    final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
    print('Push permission: ${settings.authorizationStatus}');

    // iOS: register for remote notifications
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    }

    // Subscribe to global topic if enabled (iOS: wait for APNs token)
    if (await _areNotificationsEnabled()) {
      try {
        if (Platform.isIOS) {
          // Poll briefly for APNs token to avoid startup race
          final apns = await _messaging.getAPNSToken();
          if (apns == null) {
            for (int i = 0; i < 5; i++) {
              await Future.delayed(const Duration(milliseconds: 400));
              final retry = await _messaging.getAPNSToken();
              if (retry != null) break;
            }
          }
        }
        await _messaging.subscribeToTopic('weekly');
      } catch (e) {
        // Soft-fail to avoid crash on iOS cold start; will be retried in schedulePeriodicNotifications
        print('FCM topic subscribe deferred: $e');
      }
    }

    // Foreground handling → show local notification
    bool shownInitial = false;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification != null) {
        if (!shownInitial) {
          shownInitial = true;
        } else if (notification.title == 'Weekly Reminder') {
          // allow only one visible notification per foreground session
          return;
        }
        await _local.show(
          id: notification.hashCode,
          title: notification.title ?? 'AthleteHub',
          body: notification.body ?? '',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'weekly_channel', 
              'Weekly Reminders', 
              importance: Importance.high, 
              priority: Priority.high, 
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // Persist token for backend (optional)
    await _saveFcmToken();
  }

  Future<void> _saveFcmToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).set({'fcmToken': token}, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Check if user has notifications enabled
  Future<bool> _areNotificationsEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['pushNotifications'] ?? true;
      }
      return true; // Default to enabled
    } catch (e) {
      print('Error checking notification settings: $e');
      return false;
    }
  }

  // Send notification (this would integrate with actual push notification service)
  Future<void> sendNotification() async {
    try {
      final notificationsEnabled = await _areNotificationsEnabled();
      if (!notificationsEnabled) {
        print('Notifications disabled for user');
        return;
      }

      final message = getRandomMessage();
      final user = _auth.currentUser;
      
      if (user != null) {
        // Log notification to Firebase for tracking
        await _firestore.collection('users').doc(user.uid).collection('notifications').add({
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'reminder',
          'read': false,
        });

        print('Notification logged: $message');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Schedule periodic notifications (this would be handled by a background service)
  Future<void> schedulePeriodicNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check user's notification preferences
      final notificationsEnabled = await _areNotificationsEnabled();
      if (!notificationsEnabled) return;

      // Topic-based subscription ensures backend can send weekly pushes
      if (await _areNotificationsEnabled()) {
        await _messaging.subscribeToTopic('weekly');
      } else {
        await _messaging.unsubscribeFromTopic('weekly');
      }
      
      // Local fallback could be added here if needed
      
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  // Get user's notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'message': data['message'] ?? '',
          'timestamp': data['timestamp'],
          'type': data['type'] ?? 'reminder',
          'read': data['read'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
} 