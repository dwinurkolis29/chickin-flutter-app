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

  // membuat focus node
  final FocusNode _focusNodeUsername = FocusNode();
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePhone = FocusNode();
  final FocusNode _focusNodeAddress = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();

  // membuat text editing controller
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPhone = TextEditingController();
  final TextEditingController _controllerAddress = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConFirmPassword =
      TextEditingController();

  final AuthController _authController = AuthController();

  // membuat variabel untuk menyimpan password visibility
  bool _obscurePassword = true;
  bool _isLoading = false;

  // membuat method untuk signup
  void signup() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user profile
      final profile = UserProfile(
        name: _controllerUsername.text.trim(),
        phone: _controllerPhone.text.trim(),
        address: _controllerAddress.text.trim(),
      );

      // Call AuthController
      final result = await _authController.signUp(
        email: _controllerEmail.text.trim(),
        password: _controllerPassword.text,
        profile: profile,
      );

      if (!mounted) return;

      if (result.success) {
        AppSnackbar.showSuccess(context, 'Registrasi Sukses');

        _formKey.currentState?.reset();
        // Return email only (no password for security)
        Navigator.pop(context, {
          'email': _controllerEmail.text.trim(),
        });
      } else {
        // Show error dialog
        DialogHelper.showError(
          context,
          'Registrasi Gagal',
          result.errorMessage ?? 'Terjadi kesalahan yang tidak terduga',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Form(
        key: _formKey,
        // menggunakan scroll view agar form dapat di scroll
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              // Header aplikasi
              const SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // load gambar
                  const Image(
                    width: 50,
                    height: 50,
                    image: AssetImage('images/hen.png'),
                  ),
                  Text(
                    "Recording App",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Silahkan daftar terlebih dahulu",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 35),

              // Username field
              TextFormField(
                controller: _controllerUsername,
                focusNode: _focusNodeUsername,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // melakukan validasi username tidak boleh kosong
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Masukkan username.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeEmail.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Email field
              TextFormField(
                controller: _controllerEmail,
                focusNode: _focusNodeEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // melakukan validasi email dengan regex
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  // RFC 5322 simplified regex
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodePhone.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Phone field
              TextFormField(
                controller: _controllerPhone,
                focusNode: _focusNodePhone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeAddress.requestFocus(),
              ),
              const SizedBox(height: 10),
              // Address field
              TextFormField(
                controller: _controllerAddress,
                focusNode: _focusNodeAddress,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: "Address",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodePassword.requestFocus(),
              ),
              const SizedBox(height: 10),
              // Password field
              TextFormField(
                controller: _controllerPassword,
                obscureText: _obscurePassword,
                focusNode: _focusNodePassword,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        // menampilkan password secara tersembunyi
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon:
                        _obscurePassword
                            ? const Icon(Icons.visibility_outlined)
                            : const Icon(Icons.visibility_off_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // melakukan validasi password tidak boleh kosong
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Password tidak boleh kosong.";
                  } else if (value.length < 8) {
                    // melakukan validasi password minimal 8 karakter
                    return "Password minimal 8 karakter.";
                  }
                  return null;
                },
                onEditingComplete:
                    () => _focusNodeConfirmPassword.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Confirm password field
              TextFormField(
                controller: _controllerConFirmPassword,
                obscureText: _obscurePassword,
                focusNode: _focusNodeConfirmPassword,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        // menampilkan password secara tersembunyi
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon:
                        _obscurePassword
                            ? const Icon(Icons.visibility_outlined)
                            : const Icon(Icons.visibility_off_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // melakukan validasi password tidak boleh kosong
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Password tidak boleh kosong.";
                    // melakukan validasi password tidak cocok dengan password sebelumnya
                  } else if (value != _controllerPassword.text) {
                    return "Password tidak cocok.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 50),

              // tombol register
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // memanggil fungsi signup
                    onPressed: _isLoading ? null : signup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text("Register"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sudah punya akun?"),
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text("Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // membuang focus node agar tidak terjadi memory leak
    _focusNodeUsername.dispose();
    _focusNodeEmail.dispose();
    _focusNodePhone.dispose();
    _focusNodeAddress.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();

    // membuang controller agar tidak terjadi memory leak
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPhone.dispose();
    _controllerAddress.dispose();
    _controllerPassword.dispose();
    _controllerConFirmPassword.dispose();

    super.dispose();
  }
}
