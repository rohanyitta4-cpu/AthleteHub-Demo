import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'main_navigation_screen.dart';
import 'notification_service.dart';
import 'widgets/haptic_helper.dart';
import 'utils/friendly_error.dart';

/// Professional outlined icons: black stroke, white middle on light background.
const Color _iconBlack = Color(0xFF171717);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
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
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      HapticHelper.lightImpact();
      setState(() => _isLoading = true);
      try {
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted && FirebaseAuth.instance.currentUser != null) {
          HapticHelper.mediumImpact();
          final notificationService = NotificationService();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(
                notificationService: notificationService,
              ),
            ),
          );
        }
      } catch (e) {
        HapticHelper.mediumImpact();
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyError(e, "Couldn't sign in")),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
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
                    const SizedBox(height: 56),
                    Text(
                      'AthleteHub',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 44,
                        letterSpacing: 10,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track. Improve. Dominate.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
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
                            Text(
                              'Sign in',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              style: GoogleFonts.inter(color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: _iconBlack,
                                  size: 22,
                                ),
                                labelStyle: GoogleFonts.inter(
                                    color: const Color(0xFF737373), fontSize: 14),
                                hintStyle: GoogleFonts.inter(
                                    color: const Color(0xFFA3A3A3), fontSize: 14),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF404040), width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Colors.red.shade400, width: 1),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your email.';
                                if (!v.contains('@')) return 'Enter a valid email.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: _iconBlack,
                                  size: 22,
                                ),
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
                                ),
                                labelStyle: GoogleFonts.inter(
                                    color: const Color(0xFF737373), fontSize: 14),
                                hintStyle: GoogleFonts.inter(
                                    color: const Color(0xFFA3A3A3), fontSize: 14),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF404040), width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Colors.red.shade400, width: 1),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your password.';
                                if (v.length < 6) return 'At least 6 characters.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _login,
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
                                            'Sign in',
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
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    HapticHelper.lightImpact();
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  child: Text(
                                    'Create account',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF404040),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    HapticHelper.lightImpact();
                                    Navigator.pushNamed(
                                        context, '/forgot-password');
                                  },
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF737373),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
