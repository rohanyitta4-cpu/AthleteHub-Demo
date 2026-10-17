import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_urls.dart';
import '../services/user_data_export_service.dart';
import 'scout_data_sharing_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Deleting your account…')),
            ],
          ),
        ),
      ),
    );

    try {
      // Server deletes all data (including subcollections and shared Scout data) and the login.
      await FirebaseFunctions.instance
          .httpsCallable(
            'deleteMyAccount',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
          )
          .call();
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('deleteMyAccount failed: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't delete your account. Check your connection and try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadMyData() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Preparing your data…')),
            ],
          ),
        ),
      ),
    );
    try {
      final file = await UserDataExportService.instance.writeJsonFile();
      if (!mounted) return;
      Navigator.of(context).pop();
      await Share.shareXFiles([XFile(file.path)], subject: 'My AthleteHub data');
    } catch (e) {
      debugPrint('Data export failed: $e');
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't export your data. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Profile Visibility',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coming soon. Public profiles and shared stats aren’t available yet.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingsCard(
                    context,
                    title: 'Public Profile',
                    subtitle: 'Coming soon',
                    value: false,
                    enabled: false,
                    onChanged: (_) {},
                  ),

                  const SizedBox(height: 12),

                  _buildSettingsCard(
                    context,
                    title: 'Public Stats',
                    subtitle: 'Coming soon',
                    value: false,
                    enabled: false,
                    onChanged: (_) {},
                  ),

                  const SizedBox(height: 24),

                  // Data Collection
                  Text(
                    'Data & Analytics',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildActionCard(
                    context,
                    icon: Icons.insights_outlined,
                    title: 'Share Stats to Improve Scout',
                    subtitle: 'Off by default. See what\'s shared and turn it on or off.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScoutDataSharingScreen()),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Data Management
                  Text(
                    'Data Management',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildActionCard(
                    context,
                    icon: Icons.download_outlined,
                    title: 'Download My Data',
                    subtitle: 'A copy of your profile, seasons and games (JSON)',
                    onTap: _downloadMyData,
                  ),

                  const SizedBox(height: 12),

                  _buildActionCard(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and all data',
                    onTap: _deleteAccount,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 24),

                  // Privacy Policy
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.onSurface, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Privacy Information',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your privacy is important to us. We only collect data necessary to provide our services and improve your experience.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.grey[300] : Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(AppUrls.privacyPolicy),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: const Text('View Privacy Policy'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = enabled
        ? theme.textTheme.bodyLarge?.color
        : theme.disabledColor;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.disabledColor,
            ),
          ),
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.disabledColor,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.disabledColor),
        onTap: onTap,
      ),
    );
  }
}




