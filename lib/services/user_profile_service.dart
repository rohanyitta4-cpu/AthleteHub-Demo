import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_profile.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('userProfiles').doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create or update user profile
  static Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('userProfiles').doc(profile.uid).set(profile.toMap());
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Upload profile picture
  static Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      // Verify file exists
      if (!await imageFile.exists()) {
        print('❌ [PROFILE] Image file does not exist: ${imageFile.path}');
        return null;
      }

      // Create storage reference matching storage rules
      final storageRef = _storage.ref().child('profilePictures/$userId.jpg');

      print('📤 [PROFILE] Storage path: ${storageRef.fullPath}');
      print('📤 [PROFILE] Starting upload for user: $userId');
      print('📤 [PROFILE] File size: ${await imageFile.length()} bytes');

      // Upload metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // Cache for 1 year
      );

      // Upload the file with metadata (overwrite if exists)
      final uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Verify upload was successful
      print('📊 [PROFILE] Upload state: ${snapshot.state}');
      print('📊 [PROFILE] Bytes transferred: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      
      if (snapshot.state != TaskState.success) {
        print('❌ [PROFILE] Upload failed with state: ${snapshot.state}');
        return null;
      }
      
      print('✅ [PROFILE] File uploaded successfully!');
      print('📊 [PROFILE] Snapshot ref path: ${snapshot.ref.fullPath}');
      print('📊 [PROFILE] Getting download URL...');
      
      // Get download URL with retry mechanism - Firebase Storage sometimes needs a moment
      String downloadUrl = '';
      int retryCount = 0;
      const maxRetries = 5;
      
      while (downloadUrl.isEmpty && retryCount < maxRetries) {
        try {
          // Try using snapshot.ref directly (most reliable after upload)
          downloadUrl = await snapshot.ref.getDownloadURL();
          if (downloadUrl.isNotEmpty) {
            break;
          }
        } catch (e) {
          print('⚠️ [PROFILE] Attempt ${retryCount + 1}/$maxRetries failed: $e');
          retryCount++;
          if (retryCount < maxRetries) {
            // Exponential backoff: wait 200ms, 400ms, 800ms, 1600ms
            await Future.delayed(Duration(milliseconds: 200 * (1 << retryCount)));
          }
        }
      }
      
      // If snapshot.ref failed, try storageRef as final fallback
      if (downloadUrl.isEmpty) {
        try {
          downloadUrl = await storageRef.getDownloadURL();
        } catch (e) {
          print('❌ [PROFILE] All attempts failed, last error: $e');
          return null;
        }
      }
      
      if (downloadUrl.isEmpty) {
        print('❌ [PROFILE] Download URL is empty after all retries');
        return null;
      }
      
      print('✅ [PROFILE] Got download URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      print('❌ [PROFILE] Error uploading profile picture: $e');
      print('❌ [PROFILE] Stack trace: $stackTrace');
      return null;
    }
  }

  // Update profile picture
  static Future<bool> updateProfilePicture(String userId, String imageUrl) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'profilePictureUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error updating profile picture: $e');
      return false;
    }
  }

  // Update user preferences
  static Future<bool> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'preferences': preferences,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error updating preferences: $e');
      return false;
    }
  }

  // Update favorite stats
  static Future<bool> updateFavoriteStats(String userId, List<String> favoriteStats) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'favoriteStats': favoriteStats,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error updating favorite stats: $e');
      return false;
    }
  }

  // Create initial profile for new user
  static Future<bool> createInitialProfile(String uid, String email, String displayName) async {
    try {
      final profile = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: {
          'theme': 'light',
          'notifications': true,
          'defaultChartType': 'line',
        },
        favoriteStats: ['points', 'rebounds', 'assists'],
      );
      
      return await saveUserProfile(profile);
    } catch (e) {
      print('Error creating initial profile: $e');
      return false;
    }
  }

  // Listen to profile changes
  static Stream<UserProfile?> listenToUserProfile(String userId) {
    return _firestore.collection('userProfiles').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
