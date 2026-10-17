import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/enter_stats_navigator.dart';
import '../services/pro_entitlements.dart';
import 'pro_upgrade_screen.dart';

class EntryModeSettingsScreen extends StatefulWidget {
  const EntryModeSettingsScreen({super.key});

  @override
  State<EntryModeSettingsScreen> createState() => _EntryModeSettingsScreenState();
}

class _EntryModeSettingsScreenState extends State<EntryModeSettingsScreen> {
  String _selectedEntryMode = 'flashcard';
  bool _isPro = false;
  StreamSubscription<DocumentSnapshot>? _proSubscription;

  @override
  void initState() {
    super.initState();
    _loadEntryMode();
    _loadProStatus();
    _listenPro();
  }

  void _listenPro() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _proSubscription?.cancel();
    _proSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final pro =
          snap.exists ? ((snap.data()?['isProMode'] as bool?) ?? false) : false;
      if (pro != _isPro) {
        setState(() => _isPro = pro);
      }
    });
  }

  @override
  void dispose() {
    _proSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final pro = doc.exists ? ((doc.data()?['isProMode'] as bool?) ?? false) : false;
      if (mounted) setState(() => _isPro = pro);
    } catch (_) {}
  }

  Future<void> _loadEntryMode() async {
    final mode = await EnterStatsNavigator.getEntryMode();
    if (mounted) {
      setState(() {
        _selectedEntryMode = mode;
      });
    }
  }

  Future<void> _selectEntryMode(String modeId) async {
    if (modeId == EnterStatsNavigator.formMode &&
        !ProEntitlements.canUseZunoAiEntry(_isPro)) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('AthleteHub Pro'),
          content: Text(
            'AI (Zuno) stats entry is a Pro feature.\n\n${ProEntitlements.proTierSummary}',
            style: GoogleFonts.inter(height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('View Pro'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
        );
        await _loadProStatus();
      }
      return;
    }

    setState(() {
      _selectedEntryMode = modeId;
    });
    await EnterStatsNavigator.setEntryMode(modeId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Entry mode set to ${modeId == 'form' ? 'AI (Zuno)' : 'Flashcard'}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
        ),
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
          'Stats Entry Mode',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.onSurface, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Flashcard mode is recommended for quick entry after games. You can switch to AI (Zuno) chat anytime.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Flashcard first — default / recommended
            _buildModeCard(
              context,
              title: 'Flashcard Entry',
              subtitle: 'Recommended · Quick tapping after games',
              description: 'Enter stats quickly by tapping through flashcards. Best default while coach features roll out.',
              icon: Icons.view_carousel_outlined,
              modeId: 'flashcard',
              isSelected: _selectedEntryMode == 'flashcard',
              onTap: () => _selectEntryMode('flashcard'),
            ),

            const SizedBox(height: 16),

            _buildModeCard(
              context,
              title: 'AI (Zuno)',
              subtitle: ProEntitlements.canUseZunoAiEntry(_isPro)
                  ? 'Chat to log stats in conversation'
                  : 'Pro · Chat to log stats with Zuno',
              description: ProEntitlements.canUseZunoAiEntry(_isPro)
                  ? 'Talk with Zuno and it can extract stats from what you say. Optional if you prefer chat over flashcards.'
                  : 'Unlock with Pro: conversational stats entry powered by Zuno.',
              icon: Icons.smart_toy_outlined,
              modeId: 'form',
              isSelected: _selectedEntryMode == 'form',
              locked: !ProEntitlements.canUseZunoAiEntry(_isPro),
              onTap: () => _selectEntryMode('form'),
            ),

            const SizedBox(height: 24),

            // Current Selection Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurface,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Mode',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.disabledColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedEntryMode == 'form' ? 'AI (Zuno)' : 'Flashcard Entry',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String modeId,
    required bool isSelected,
    bool locked = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.onSurface;
    final onAccent = theme.colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: isSelected ? 3 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? accent.withValues(alpha: 0.08)
                : (isDark ? Colors.grey[900] : Colors.white),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? onAccent : accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (locked)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.lock_outline, size: 22, color: theme.disabledColor),
                    ),
                  if (isSelected)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: Icon(
                        Icons.check,
                        color: onAccent,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





