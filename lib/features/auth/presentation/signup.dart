import 'package:flutter/material.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/auth/controllers/auth_controller.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodeUsername        = FocusNode();
  final FocusNode _focusNodeEmail           = FocusNode();
  final FocusNode _focusNodePhone           = FocusNode();
  final FocusNode _focusNodeAddress         = FocusNode();
  final FocusNode _focusNodePassword        = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();

  final TextEditingController _controllerUsername        = TextEditingController();
  final TextEditingController _controllerEmail           = TextEditingController();
  final TextEditingController _controllerPhone           = TextEditingController();
  final TextEditingController _controllerAddress         = TextEditingController();
  final TextEditingController _controllerPassword        = TextEditingController();
  final TextEditingController _controllerConFirmPassword = TextEditingController();

  final AuthController _authController = AuthController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading              = false;

  // ─── Logic tidak diubah ──────────────────────────────────────────────────────
  void signup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        name:    _controllerUsername.text.trim(),
        phone:   _controllerPhone.text.trim(),
        address: _controllerAddress.text.trim(),
      );

      final result = await _authController.signUp(
        email:    _controllerEmail.text.trim(),
        password: _controllerPassword.text,
        profile:  profile,
      );

      if (!mounted) return;

      if (result.success) {
        AppSnackbar.showSuccess(context, 'Registrasi Sukses');
        _formKey.currentState?.reset();
        Navigator.pop(context, {'email': _controllerEmail.text.trim()});
      } else {
        DialogHelper.showError(
          context,
          'Registrasi Gagal',
          result.errorMessage ?? 'Terjadi kesalahan yang tidak terduga',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool busy = _isLoading;

    final Color fieldFill    = scheme.surfaceContainerHighest;
    final Color iconColor    = scheme.onSurfaceVariant;
    final Color primaryColor = scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,
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
                  'Create your\nRecording App account',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color:      scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height:     1.4,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Username ──
                _buildField(
                  controller:       _controllerUsername,
                  textTheme:        textTheme,
                  focusNode:        _focusNodeUsername,
                  hint:             'Username',
                  icon:             Icons.person_outline,
                  keyboardType:     TextInputType.name,
                  enabled:          !busy,
                  fieldFill:        fieldFill,
                  iconColor:        iconColor,
                  scheme:           scheme,
                  onEditingComplete: () => _focusNodeEmail.requestFocus(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan username.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Email ──
                _buildField(
                  controller:       _controllerEmail,
                  textTheme:        textTheme,
                  focusNode:        _focusNodeEmail,
                  hint:             'E-mail',
                  icon:             Icons.mail_outline,
                  keyboardType:     TextInputType.emailAddress,
                  enabled:          !busy,
                  fieldFill:        fieldFill,
                  iconColor:        iconColor,
                  scheme:           scheme,
                  onEditingComplete: () => _focusNodePhone.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Phone ──
                _buildField(
                  controller:       _controllerPhone,
                  textTheme:        textTheme,
                  focusNode:        _focusNodePhone,
                  hint:             'Phone',
                  icon:             Icons.phone_outlined,
                  keyboardType:     TextInputType.phone,
                  enabled:          !busy,
                  fieldFill:        fieldFill,
                  iconColor:        iconColor,
                  scheme:           scheme,
                  onEditingComplete: () => _focusNodeAddress.requestFocus(),
                ),
                const SizedBox(height: 12),

                // ── Address ──
                _buildField(
                  controller:       _controllerAddress,
                  textTheme:        textTheme,
                  focusNode:        _focusNodeAddress,
                  hint:             'Address',
                  icon:             Icons.location_on_outlined,
                  keyboardType:     TextInputType.streetAddress,
                  enabled:          !busy,
                  fieldFill:        fieldFill,
                  iconColor:        iconColor,
                  scheme:           scheme,
                  onEditingComplete: () => _focusNodePassword.requestFocus(),
                ),
                const SizedBox(height: 12),

                // ── Password ──
                _buildField(
                  controller:   _controllerPassword,
                  textTheme:    textTheme,
                  focusNode:    _focusNodePassword,
                  hint:         'Password',
                  icon:         Icons.lock_outline,
                  obscureText:  _obscurePassword,
                  enabled:      !busy,
                  fieldFill:    fieldFill,
                  iconColor:    iconColor,
                  scheme:       scheme,
                  onEditingComplete: () => _focusNodeConfirmPassword.requestFocus(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong.';
                    }
                    if (value.length < 8) {
                      return 'Password minimal 8 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Confirm Password ──
                _buildField(
                  controller:  _controllerConFirmPassword,
                  textTheme:   textTheme,
                  focusNode:   _focusNodeConfirmPassword,
                  hint:        'Konfirmasi Password',
                  icon:        Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  enabled:     !busy,
                  fieldFill:   fieldFill,
                  iconColor:   iconColor,
                  scheme:      scheme,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong.';
                    }
                    if (value != _controllerPassword.text) {
                      return 'Password tidak cocok.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Register Button ──
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         primaryColor,
                      foregroundColor:         scheme.onPrimary,
                      disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: busy ? null : signup,
                    child: _isLoading
                        ? SizedBox(
                            width:  20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                            ),
                          )
                        : Text(
                            'Register',
                            style: textTheme.bodyLarge?.copyWith(
                              color:      scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Footer ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: busy ? null : () => Navigator.pop(context),
                      child: Text(
                        'Sign in',
                        style: textTheme.bodyMedium?.copyWith(
                          color:           scheme.primary,
                          fontWeight:      FontWeight.w700,
                          decoration:      TextDecoration.underline,
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
    bool enabled    = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    VoidCallback? onEditingComplete,
  }) {
    return TextFormField(
      controller:        controller,
      focusNode:         focusNode,
      obscureText:       obscureText,
      enabled:           enabled,
      keyboardType:      keyboardType,
      onEditingComplete: onEditingComplete,
      validator:         validator,
      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
    );
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _focusNodeUsername.dispose();
    _focusNodeEmail.dispose();
    _focusNodePhone.dispose();
    _focusNodeAddress.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();

    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPhone.dispose();
    _controllerAddress.dispose();
    _controllerPassword.dispose();
    _controllerConFirmPassword.dispose();

    super.dispose();
  }
}