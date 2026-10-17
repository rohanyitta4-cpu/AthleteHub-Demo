import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import 'config/app_urls.dart';
import 'config/feature_flags.dart';
import 'services/performance_analysis/performance_analysis_service.dart';
import 'models/user_profile_v2.dart';
import 'widgets/haptic_helper.dart';
import 'utils/friendly_error.dart';

/// Professional outlined icons: black stroke, white middle on light background.
const Color _iconBlack = Color(0xFF171717);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _shareStats = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final AuthService _authService = AuthService();
  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _errorMessage = 'Passwords do not match.');
        HapticHelper.mediumImpact();
        return;
      }
      HapticHelper.lightImpact();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          role: UserRole.player,
          inviteCode: _inviteCodeController.text.trim().isNotEmpty
              ? _inviteCodeController.text.trim()
              : null,
        );
        if (_shareStats) {
          try {
            await PerformanceAnalysisService().setDataSharing(enabled: true);
          } catch (e) {
            debugPrint('setDataSharing after signup: $e');
          }
        }
        if (mounted) {
          HapticHelper.mediumImpact();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please sign in.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF404040),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          HapticHelper.mediumImpact();
          setState(() {
            _errorMessage = friendlyError(e, "Couldn't create your account");
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildRolePicker() {
    Widget option({
      required IconData icon,
      required String label,
      required bool selected,
      String? badge,
    }) {
      final enabled = badge == null;
      return Expanded(
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF171717) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? const Color(0xFF171717) : const Color(0xFFE5E5E5),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 22, color: selected ? Colors.white : _iconBlack),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF737373),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF404040),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            option(icon: Icons.person_outline, label: 'Player', selected: true),
            const SizedBox(width: 10),
            option(
              icon: Icons.groups_outlined,
              label: 'Coach',
              selected: false,
              badge: FeatureFlags.coachAccounts ? null : 'Coming soon',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareStatsQuestion() {
    const accent = Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _shareStats ? accent.withValues(alpha: 0.6) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your stats to help improve Scout?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saves your season totals (no name, email, team or dates) so we can '
                  'check Scout\'s grading standards against real players. Never changes '
                  'your grade. Change it any time in Settings. Under 18? Ask a parent or guardian first.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: const Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse(AppUrls.privacyPolicy),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'Privacy policy',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF404040),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _shareStats,
            onChanged: _isLoading
                ? null
                : (v) {
                    HapticHelper.selection();
                    setState(() => _shareStats = v);
                  },
            activeThumbColor: accent,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildDecoration(String label,
      {IconData? prefixIcon, Widget? suffixIcon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _iconBlack, size: 22)
          : null,
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.inter(color: const Color(0xFF737373), fontSize: 14),
      hintStyle: GoogleFonts.inter(color: const Color(0xFFA3A3A3), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF404040), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(useMaterial3: true),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Create account',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE5E5E5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildRolePicker(),
                            const SizedBox(height: 20),
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: _iconBlack, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            TextFormField(
                              controller: _emailController,
                              style: GoogleFonts.inter(color: Colors.black87),
                              decoration: _buildDecoration('Email',
                                  prefixIcon: Icons.email_outlined,
                                  hint: 'you@example.com'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your email.';
                                if (!_emailRegex.hasMatch(v)) return 'Enter a valid email.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(color: Colors.black87),
                              decoration: _buildDecoration('Password',
                                  prefixIcon: Icons.lock_outline,
                                  hint: '••••••••',
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      HapticHelper.selection();
                                      setState(() =>
                                          _obscurePassword = !_obscurePassword);
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _iconBlack,
                                      size: 22,
                                    ),
                                  )),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter a password.';
                                if (v.length < 6) return 'At least 6 characters.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              style: GoogleFonts.inter(color: Colors.black87),
                              decoration: _buildDecoration('Confirm password',
                                  prefixIcon: Icons.lock_outline,
                                  hint: '••••••••',
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      HapticHelper.selection();
                                      setState(() =>
                                          _obscureConfirm = !_obscureConfirm);
                                    },
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _iconBlack,
                                      size: 22,
                                    ),
                                  )),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Confirm your password.';
                                if (v != _passwordController.text) return 'Passwords do not match.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _inviteCodeController,
                              style: GoogleFonts.inter(color: Colors.black87),
                              decoration: _buildDecoration(
                                'Team invite code (optional)',
                                prefixIcon: Icons.group_add_outlined,
                                hint: 'Enter code from your coach',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'If your coach shared a team code, enter it here.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF737373),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildShareStatsQuestion(),
                            const SizedBox(height: 28),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _signup,
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: _isLoading
                                        ? const Color(0xFFA3A3A3)
                                        : const Color(0xFF262626),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: _isLoading
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            'Create account',
                                            style: GoogleFonts.inter(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                HapticHelper.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Already have an account? Sign in',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF404040),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
