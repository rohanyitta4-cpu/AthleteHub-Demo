import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/feature_flags.dart';
import '../models/user_profile_v2.dart';
import '../screens/dashboard_screen.dart';
import '../screens/coach_navigation_screen.dart';

class NavigationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user role and navigate accordingly
  static Future<void> navigateBasedOnRole(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // User document doesn't exist, redirect to login
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      
      if (role == 'coach' && FeatureFlags.coachAccounts) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CoachNavigationScreen()),
        );
      } else {
        // Default to player dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      print('Error navigating based on role: $e');
      // Fallback to player dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  /// Get current user's role
  static Future<UserRole?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final roleString = userData['role'] as String?;
      
      if (roleString == 'coach' && FeatureFlags.coachAccounts) {
        return UserRole.coach;
      } else {
        return UserRole.player;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Check if user is a coach
  static Future<bool> isCoach() async {
    final role = await getCurrentUserRole();
    return role == UserRole.coach;
  }

  /// Check if user is a player
  static Future<bool> isPlayer() async {
    final role = await getCurrentUserRole();
    return role == UserRole.player;
  }

  /// Get user profile
  static Future<UserProfileV2?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserProfileV2.fromJson(userDoc.data()!);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
}
