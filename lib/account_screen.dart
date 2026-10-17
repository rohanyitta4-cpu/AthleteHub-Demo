import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'notification_service.dart';
import 'models/player_profile.dart';
import 'screens/themes_settings_screen.dart';
import 'screens/notifications_settings_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/privacy_settings_screen.dart';
import 'screens/hitting_profile_settings_screen.dart';
import 'screens/scout_data_sharing_screen.dart';
import 'services/performance_analysis/performance_analysis_service.dart';
import 'screens/pro_upgrade_screen.dart';
import 'services/pro_entitlements.dart';
import 'services/user_data_export_service.dart';
import 'services/pdf_report_service.dart';
import 'package:share_plus/share_plus.dart';
import 'utils/friendly_error.dart';

class AccountScreen extends StatefulWidget {
  final NotificationService notificationService;
  final VoidCallback? onProfileUpdated;

  const AccountScreen({
    super.key,
    required this.notificationService,
    this.onProfileUpdated,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  String? _userName;
  String? _profilePictureUrl;
  String? _userEmail;
  bool _isUploadingProfilePic = false;
  bool _isProMode = false;
  bool _shareStats = false;
  bool _savingShareStats = false;
  CompetitionLevel? _competitionLevel;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _listenUserDocForPro();
  }

  /// Unlocks export / PDF UI immediately when [isProMode] flips after purchase.
  void _listenUserDocForPro() {
    final user = _auth.currentUser;
    if (user == null) return;
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          final data = snap.data() ?? const <String, dynamic>{};
          final pro = (data['isProMode'] as bool?) ?? false;
          final sharing = data['scoutDataSharing'];
          final share = sharing is Map && sharing['enabled'] == true;
          final level = CompetitionLevel.fromId(
            data['competitionLevel'] as String?,
          );
          setState(() {
            _isProMode = pro;
            if (!_savingShareStats) _shareStats = share;
            _competitionLevel = level;
          });
        });
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setShareStats(bool enabled) async {
    setState(() {
      _shareStats = enabled;
      _savingShareStats = true;
    });
    try {
      await PerformanceAnalysisService().setDataSharing(
        enabled: enabled,
        competitionLevel: _competitionLevel,
      );
      if (mounted && !enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Stat sharing is off and the numbers you shared were deleted.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _shareStats = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't update stat sharing. Check your connection and try again.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingShareStats = false);
    }
  }

  Future<void> _editDisplayName() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: _userName ?? '');
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text('Display name', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Your name',
              counterText: '',
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.disabledColor)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (next == null || !mounted) return;

    final trimmed = next.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name to continue.')),
      );
      return;
    }
    if (trimmed == (_userName ?? '').trim()) return;

    try {
      await user.updateDisplayName(trimmed);
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': trimmed,
      }, SetOptions(merge: true));
      await _firestore.collection('playerProfiles').doc(user.uid).set({
        'displayName': trimmed,
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _userName = trimmed);
      widget.onProfileUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, "Couldn't update your name")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _userEmail = user.email;

        // Try loading from users collection first (primary source)
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        final bool isPro = userDoc.exists
            ? ((userDoc.data()?['isProMode'] as bool?) ?? false)
            : false;

        if (userDoc.exists &&
            userDoc.data()?.containsKey('profilePictureUrl') == true) {
          if (mounted) {
            setState(() {
              _userName =
                  userDoc.get('displayName') as String? ??
                  user.displayName ??
                  'Player';
              _profilePictureUrl = userDoc.get('profilePictureUrl') as String?;
              _isProMode = isPro;
            });
          }
        } else {
          // Fallback to playerProfiles collection
          final profileDoc = await _firestore
              .collection('playerProfiles')
              .doc(user.uid)
              .get();

          if (profileDoc.exists) {
            final profile = PlayerProfile.fromFirestore(profileDoc);
            if (mounted) {
              setState(() {
                _userName = profile.displayName ?? user.displayName ?? 'Player';
                _profilePictureUrl = profile.profilePictureUrl;
                _isProMode = isPro;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _userName = user.displayName ?? 'Player';
                _isProMode = isPro;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _pickAndUploadProfilePicture(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Compress image to reduce upload size
        maxWidth: 1024, // Resize to max 1024px width
        maxHeight: 1024, // Resize to max 1024px height
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      setState(() {
        _isUploadingProfilePic = true;
      });

      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _isUploadingProfilePic = false);
        }
        return;
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw Exception('Selected image file does not exist');
      }

      // Create storage reference
      final storage = FirebaseStorage.instance;
      final storageRef = storage
          .ref()
          .child('profilePictures')
          .child('${user.uid}.jpg');

      print('📤 [PROFILE] Storage path: ${storageRef.fullPath}');
      print('📤 [PROFILE] Starting upload for user: ${user.uid}');
      print('📤 [PROFILE] File size: ${await file.length()} bytes');

      // Upload metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // Cache for 1 year
      );

      // Upload the file with metadata (overwrite if exists)
      final uploadTask = storageRef.putFile(file, metadata);

      // Wait for upload to complete and check state
      final snapshot = await uploadTask;

      // Verify upload was successful
      print('📊 [PROFILE] Upload state: ${snapshot.state}');
      print(
        '📊 [PROFILE] Bytes transferred: ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
      );

      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
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
          print(
            '⚠️ [PROFILE] Attempt ${retryCount + 1}/$maxRetries failed: $e',
          );
          retryCount++;
          if (retryCount < maxRetries) {
            // Exponential backoff: wait 200ms, 400ms, 800ms, 1600ms
            await Future.delayed(
              Duration(milliseconds: 200 * (1 << retryCount)),
            );
          }
        }
      }

      // If snapshot.ref failed, try storageRef as final fallback
      if (downloadUrl.isEmpty) {
        try {
          downloadUrl = await storageRef.getDownloadURL();
        } catch (e) {
          print('❌ [PROFILE] All attempts failed, last error: $e');
          throw Exception(
            'Failed to get download URL after $maxRetries attempts: $e',
          );
        }
      }

      if (downloadUrl.isEmpty) {
        throw Exception('Download URL is empty after all retries');
      }

      print('✅ [PROFILE] Got download URL: $downloadUrl');

      // Update both users and playerProfiles collections for compatibility
      await Future.wait([
        // Primary: Update users collection
        _firestore.collection('users').doc(user.uid).set({
          'profilePictureUrl': downloadUrl,
          'displayName': _userName ?? 'Player',
          'email': user.email,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),

        // Secondary: Update playerProfiles collection for backward compatibility
        _firestore
            .collection('playerProfiles')
            .doc(user.uid)
            .set({
              'profilePictureUrl': downloadUrl,
              'displayName': _userName ?? 'Player',
              'userId': user.uid,
            }, SetOptions(merge: true))
            .catchError((e) {
              print(
                '⚠️ [PROFILE] Failed to update playerProfiles (non-critical): $e',
              );
            }),
      ]);

      print('✅ [PROFILE] Profile picture URL saved to Firestore');

      if (mounted) {
        setState(() {
          _profilePictureUrl = downloadUrl;
          _isUploadingProfilePic = false;
        });

        // Notify parent that profile was updated
        widget.onProfileUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Color(0xFF10B981), // Green success color
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [PROFILE] Error uploading profile picture: $e');
      print('❌ [PROFILE] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isUploadingProfilePic = false;
        });

        final errorMessage = friendlyError(e, "Couldn't upload your photo");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _pickAndUploadProfilePicture(source),
            ),
          ),
        );
      }
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.disabledColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Profile Picture',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadProfilePicture(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.image_outlined, color: theme.colorScheme.onSurface),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadProfilePicture(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with profile picture and name
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: [
                    // Profile Picture
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: theme.primaryColor, width: 2),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isUploadingProfilePic
                              ? null
                              : _showProfilePictureOptions,
                          borderRadius: BorderRadius.circular(40),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _profilePictureUrl != null &&
                                      _profilePictureUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(39),
                                      child: Image.network(
                                        _profilePictureUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                color: theme.disabledColor,
                                                size: 40,
                                              );
                                            },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      color: theme.disabledColor,
                                      size: 40,
                                    ),

                              // Upload indicator
                              if (_isUploadingProfilePic)
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: const SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Camera icon overlay
                              if (!_isUploadingProfilePic)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: _editDisplayName,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _userName ?? 'Player',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined, size: 16, color: theme.disabledColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Settings Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Appearance'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Themes',
                      subtitle: 'Light or dark, and match accents to your rank',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ThemesSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Reminders and alerts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsSettingsScreen(
                              notificationService: widget.notificationService,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(context, 'Scout & logging'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.sports_baseball_outlined,
                      title: 'Hitting Profile',
                      subtitle: 'Power, contact, or on-base weighting for Scout',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HittingProfileSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.edit_outlined,
                      title: 'Entry Mode',
                      subtitle: 'Coming soon',
                      enabled: false,
                      onTap: () {},
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.insights_outlined,
                      title: 'Share Stats to Improve Scout',
                      subtitle: 'Off by default. Tap for what’s shared.',
                      trailing: Switch(
                        value: _shareStats,
                        onChanged: _savingShareStats ? null : _setShareStats,
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ScoutDataSharingScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(context, 'Subscription'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.workspace_premium_outlined,
                      title: 'AthleteHub Pro',
                      subtitle: 'Free for now. More features soon.',
                      enabled: false,
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(context, 'Your data'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.table_chart_outlined,
                      title: 'Export spreadsheet (CSV)',
                      subtitle: ProEntitlements.canExportData(_isProMode)
                          ? 'Every game plus season totals — Excel, Numbers, or Sheets'
                          : 'Pro — spreadsheet export for all games',
                      onTap: _exportCsv,
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.data_object_outlined,
                      title: 'Export full backup (JSON)',
                      subtitle: ProEntitlements.canExportData(_isProMode)
                          ? 'Profile, seasons, and every game'
                          : 'Pro — complete structured backup',
                      onTap: _exportJson,
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'PDF performance report',
                      subtitle: ProEntitlements.canUsePdfReport(_isProMode)
                          ? 'Season totals and full game log, ready to print'
                          : 'Pro — printable summary with picture',
                      onTap: _exportPdfReport,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader(context, 'Account'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.badge_outlined,
                      title: 'Display name',
                      subtitle: _userName?.trim().isNotEmpty == true
                          ? _userName!
                          : 'Name shown on your dashboard',
                      onTap: _editDisplayName,
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.security_outlined,
                      title: 'Security',
                      subtitle: 'Password and login',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SecuritySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      subtitle: 'Data and privacy controls',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.logout_outlined,
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      onTap: () async {
                        _showSignOutConfirmation(context);
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    if (!ProEntitlements.canExportData(_isProMode)) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
      );
      await _loadUserProfile();
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Preparing CSV…',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    try {
      final file = await UserDataExportService.instance.writeCsvFile();
      if (!mounted) return;
      Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AthleteHub stats export',
        text: 'AthleteHub CSV export',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e, "Couldn't export your data"))));
      }
    }
  }

  Future<void> _exportPdfReport() async {
    if (!ProEntitlements.canUsePdfReport(_isProMode)) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
      );
      await _loadUserProfile();
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Building PDF…',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    try {
      final file = await PdfReportService.instance.generateAthleteHubReport(
        profileImageUrl: _profilePictureUrl,
        displayNameOverride: _userName,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AthleteHub PDF report',
        text: 'AthleteHub performance report',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e, "Couldn't create the PDF"))));
      }
    }
  }

  Future<void> _exportJson() async {
    if (!ProEntitlements.canExportData(_isProMode)) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
      );
      await _loadUserProfile();
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Preparing JSON…',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    try {
      final file = await UserDataExportService.instance.writeJsonFile();
      if (!mounted) return;
      Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AthleteHub backup',
        text: 'AthleteHub JSON backup',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e, "Couldn't export your data"))));
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.disabledColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Widget? trailing,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final fg = enabled
        ? (theme.textTheme.bodyLarge?.color ?? Colors.black)
        : theme.disabledColor;
    final iconColor = enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
        : theme.disabledColor;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right,
                      color: theme.disabledColor,
                      size: 20,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sign Out'),
              onPressed: () async {
                await _auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
            ),
          ],
        );
      },
    );
  }
}
