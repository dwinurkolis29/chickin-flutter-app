import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/user/presentation/pages/form_user.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userProfile = await _firebaseService.getUserProfile();
        if (mounted) {
          setState(() {
            _userProfile = userProfile;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Pengguna tidak login';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Link reset password telah dikirim ke email Anda.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Gagal mengirim email reset: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // surface = AppColors.background (light) / M3 dark default (dark)
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FormUser(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.error),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Profile Header ──
                      _Card(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor:
                                  colorScheme.primary.withOpacity(0.12),
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userProfile?.name ?? 'Tidak ada data',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Peternak',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Contact Info ──
                      _Card(
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              value: _userProfile?.phone ?? 'Tidak ada data',
                            ),
                            Divider(
                              height: 20,
                              color: colorScheme.outlineVariant,
                            ),
                            _InfoRow(
                              icon: Icons.mail_outline,
                              value: _auth.currentUser?.email ??
                                  'Tidak ada data',
                            ),
                            Divider(
                              height: 20,
                              color: colorScheme.outlineVariant,
                            ),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              value:
                                  _userProfile?.address ?? 'Tidak ada data',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Reset Password ──
                      _Card(
                        onTap: _resetPassword,
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.lock_reset_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Reset Password',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Shared card wrapper ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        // Allows border radius to clip the InkWell ripple
        clipBehavior: Clip.antiAlias, 
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style:
                textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}