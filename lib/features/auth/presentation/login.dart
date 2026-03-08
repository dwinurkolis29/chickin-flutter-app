import 'package:flutter/material.dart';

import '../../../core/components/dialogs/dialog_helper.dart';
import '../../../core/components/snackbars/app_snackbar.dart';
import '../controllers/auth_controller.dart';
import '../../dashboard/presentation/dashboard.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final FocusNode _focusNodePassword = FocusNode();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthController _authController = AuthController();

  // ─── Email/Password Login ────────────────────────────────────────────────────
  void login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final result = await _authController.signIn(
        email: _controllerEmail.text.trim(),
        password: _controllerPassword.text,
      );
      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
      } else {
        DialogHelper.showError(
          context,
          'Login Gagal',
          result.errorMessage ?? 'Terjadi kesalahan yang tidak terduga',
        );
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(context, 'Error', 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Google Sign-In (Under Development) ─────────────────────────────────────
  void _signInWithGoogle() {
    AppSnackbar.showInfo(
      context,
      'Login dengan Google sedang dalam tahap pengembangan.',
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool busy = _isLoading;

    final Color fieldFill = scheme.surfaceContainerHighest;
    final Color iconColor = scheme.onSurfaceVariant;
    final Color primaryColor = scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface, // AppColors.background via theme
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // ── Logo ──
                Container(
                  width: 72,
                  height: 72,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logos/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Headline ──
                Text(
                  'Welcome back\nto Recording App',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Email Field ──
                _buildField(
                  controller: _controllerEmail,
                  textTheme: textTheme,
                  hint: 'E-mail',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !busy,
                  fieldFill: fieldFill,
                  iconColor: iconColor,
                  scheme: scheme,
                  onEditingComplete: () => _focusNodePassword.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Password Field ──
                _buildField(
                  controller: _controllerPassword,
                  textTheme: textTheme,
                  focusNode: _focusNodePassword,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  enabled: !busy,
                  fieldFill: fieldFill,
                  iconColor: iconColor,
                  scheme: scheme,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Login Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: scheme.onPrimary,
                      disabledBackgroundColor: primaryColor.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: busy ? null : login,
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scheme.onPrimary,
                                ),
                              ),
                            )
                            : Text(
                              'Sign in',
                              style: textTheme.bodyLarge?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Divider ──
                Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Google Sign-In Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: scheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: scheme.surface,
                    ),
                    onPressed: busy ? null : _signInWithGoogle,
                    icon: Icon(
                      Icons.g_mobiledata,
                      color: scheme.onSurface,
                      size: 24,
                    ),
                    label: Text(
                      'Continue with Google',
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Footer ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          busy
                              ? null
                              : () async {
                                _formKey.currentState?.reset();
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Signup(),
                                  ),
                                );
                                if (result != null &&
                                    result is Map<String, String>) {
                                  _controllerEmail.text = result['email'] ?? '';
                                }
                              },
                      child: Text(
                        'Sign up',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reusable Field Builder ──────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required TextTheme textTheme,
    FocusNode? focusNode,
    required String hint,
    required IconData icon,
    required Color fieldFill,
    required Color iconColor,
    required ColorScheme scheme,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    VoidCallback? onEditingComplete,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      onEditingComplete: onEditingComplete,
      validator: validator,
      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodePassword.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}
