import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/onboarding_screen.dart';
import '../models/user_team_membership.dart';
import '../models/user_profile_v2.dart';
import 'services/baseball_service.dart';
import 'services/baseball_migration_service.dart';
import 'firebase_stats_service.dart';
import 'utils/friendly_error.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp(String email, String password, {UserRole role = UserRole.player, String? inviteCode}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        String? teamId;
        
        // Handle invite code if provided
        if (inviteCode != null && inviteCode.isNotEmpty) {
          final success = await BaseballService.joinTeamViaInviteCode(inviteCode);
          if (success) {
            teamId = await BaseballMigrationService.getUserTeamId();
          } else {
            throw UserMessage('Invalid or expired invite code');
          }
        }
        
        // Create user profile
        final userProfile = UserProfileV2(
          userId: user.uid,
          displayName: email.split('@')[0], // Use email prefix as default name
          email: email,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          role: role,
          teamId: teamId,
        );
        
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userProfile.toJson(), SetOptions(merge: true));

        // Ensure History / Stats always have an active season doc on first signup.
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingName = prefs.getString(OnboardingScreen.pendingSeasonNamePrefKey);
          await FirebaseStatsService().createDefaultSeason(
            seasonName: pendingName,
          );
          await prefs.remove(OnboardingScreen.pendingSeasonNamePrefKey);
        } catch (e) {
          debugPrint('createDefaultSeason after signup: $e');
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      String userMessage;
      switch (e.code) {
        case 'email-already-in-use':
          userMessage = 'An account with this email already exists. Please sign in instead.';
          break;
        case 'invalid-email':
          userMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          userMessage = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          userMessage = 'Account creation is currently disabled. Please contact support.';
          break;
        case 'network-request-failed':
          userMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          userMessage = 'Unable to create account. Please try again.';
      }
      throw UserMessage(userMessage);
    } catch (e) {
      if (e is UserMessage) rethrow;
      throw UserMessage("An unexpected error occurred. Please try again.");
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      print('AuthService: Attempting to sign in user: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      print('AuthService: Sign in successful for user: ${user?.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
      print('AuthService: Firebase auth error: ${e.code} - ${e.message}');
      
      String userMessage;
      switch (e.code) {
        case 'user-not-found':
          userMessage = 'No account found with this email. Please check your email or create a new account.';
          break;
        case 'wrong-password':
          userMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-credential':
          userMessage = 'Incorrect email or password. Please try again.';
          break;
        case 'invalid-email':
          userMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          userMessage = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          userMessage = 'Too many failed attempts. Please try again in a few minutes.';
          break;
        case 'network-request-failed':
          userMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          userMessage = 'Sign in failed. Please try again.';
      }
      
      throw UserMessage(userMessage);
    } catch (e) {
      print('Unexpected error during sign in: $e');
      throw UserMessage("An unexpected error occurred. Please try again.");
    }
  }

  Future<void> sendPasswordResetEmail(String email, {Function()? onComplete}) async {
    try {
      print('Initiating password reset email to: $email at ${DateTime.now()}');
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://athletehub-79f45.web.app/reset?email=$email', // Your Firebase Hosting URL
          handleCodeInApp: true,
        ),
      );
      print('Password reset email sent successfully to: $email at ${DateTime.now()}');
      onComplete?.call();
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException in sendPasswordResetEmail: ${e.code} - ${e.message} at ${DateTime.now()}');
      
      String userMessage;
      switch (e.code) {
        case 'user-not-found':
          userMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          userMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          userMessage = 'Too many requests. Please try again in a few minutes.';
          break;
        default:
          userMessage = 'Unable to send password reset email. Please try again.';
      }
      
      throw UserMessage(userMessage);
    } catch (e) {
      print('Unexpected error in sendPasswordResetEmail: $e at ${DateTime.now()}');
      throw UserMessage("An unexpected error occurred. Please try again.");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Team management methods
  Future<List<UserTeamMembership>> getUserTeams() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final linkedTeams = List<String>.from(userData['linkedTeams'] ?? []);

      final teams = <UserTeamMembership>[];
      for (final teamId in linkedTeams) {
        try {
          // Get team details
          final teamDoc = await _firestore.collection('teams').doc(teamId).get();
          if (!teamDoc.exists) continue;

          final teamData = teamDoc.data()!;
          
          // Get user's role in this team
          final roleDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('roles')
              .doc(teamId)
              .get();

          final role = roleDoc.exists ? roleDoc.data()!['role'] : 'player';

          teams.add(UserTeamMembership(
            userId: user.uid,
            teamId: teamId,
            teamName: teamData['name'] ?? 'Unknown Team',
            role: role,
            joinedAt: DateTime.now(), // This should come from the actual data
            isActive: true,
            isDefault: userData['defaultTeamId'] == teamId,
          ));
        } catch (e) {
          print('Error loading team $teamId: $e');
        }
      }

      return teams;
    } catch (e) {
      print('Error loading user teams: $e');
      return [];
    }
  }

  Future<String?> getUserRole(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final roleDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('roles')
          .doc(teamId)
          .get();

      if (!roleDoc.exists) return null;
      return roleDoc.data()!['role'];
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<bool> isUserCoach(String teamId) async {
    final role = await getUserRole(teamId);
    return role == 'coach';
  }

  Future<bool> isUserPlayer(String teamId) async {
    final role = await getUserRole(teamId);
    return role == 'player';
  }

  Future<bool> isUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['admin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> setDefaultTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'defaultTeamId': teamId,
        'lastTeamSelection': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting default team: $e');
    }
  }

  Future<String?> getDefaultTeamId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      return userData['defaultTeamId'];
    } catch (e) {
      print('Error getting default team: $e');
      return null;
    }
  }

  Stream<List<UserTeamMembership>> streamUserTeams() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <UserTeamMembership>[];

      final userData = userDoc.data()!;
      final linkedTeams = List<String>.from(userData['linkedTeams'] ?? []);

      final teams = <UserTeamMembership>[];
      for (final teamId in linkedTeams) {
        try {
          // Get team details
          final teamDoc = await _firestore.collection('teams').doc(teamId).get();
          if (!teamDoc.exists) continue;

          final teamData = teamDoc.data()!;
          
          // Get user's role in this team
          final roleDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('roles')
              .doc(teamId)
              .get();

          final role = roleDoc.exists ? roleDoc.data()!['role'] : 'player';

          teams.add(UserTeamMembership(
            userId: user.uid,
            teamId: teamId,
            teamName: teamData['name'] ?? 'Unknown Team',
            role: role,
            joinedAt: DateTime.now(), // This should come from the actual data
            isActive: true,
            isDefault: userData['defaultTeamId'] == teamId,
          ));
        } catch (e) {
          print('Error loading team $teamId: $e');
        }
      }

      return teams;
    });
  }
}
