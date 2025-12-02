import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../dashboard/presentation/home.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  // focus node untuk email
  final FocusNode _focusNodePassword = FocusNode();

  // membuat controller untuk email dan password
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  // membuat variabel untuk menyimpan status password
  bool _obscurePassword = true;

  // variabel untuk loading state
  bool _isLoading = false;

  // hive box untuk login
  final Box _boxLogin = Hive.box("login");

  // hive box untuk accounts
  final Box _boxAccounts = Hive.box("accounts");

  // fungsi untuk menampilkan error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // fungsi untuk menampilkan snackbar
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // fungsi untuk login dengan validasi lengkap
  void login() async {
    // Validasi form terlebih dahulu
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Mohon isi form dengan benar');
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Menggunakan FirebaseAuth untuk login
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _controllerEmail.text.trim(),
        password: _controllerPassword.text,
      );

      // Cek apakah email sudah diverifikasi (opsional)
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        _showSnackBar('Email belum diverifikasi. Silakan cek email Anda.');
        // Opsional: kirim ulang email verifikasi
        // await userCredential.user!.sendEmailVerification();
      }

      // Login berhasil - simpan data ke Hive
      _boxLogin.put("loginStatus", true);
      _boxLogin.put("Email", _controllerEmail.text.trim());
      _boxLogin.put("userId", userCredential.user?.uid);

      // Navigasi ke halaman Home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle berbagai error dari Firebase
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
          break;
        case 'wrong-password':
          errorMessage = 'Password yang Anda masukkan salah.';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          errorMessage = 'Akun ini telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          errorMessage = 'Terlalu banyak percobaan login. Silakan coba lagi nanti.';
          break;
        case 'invalid-credential':
          errorMessage = 'Email atau password yang Anda masukkan salah.';
          break;
        case 'network-request-failed':
          errorMessage = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
          break;
        default:
          errorMessage = 'Terjadi kesalahan: ${e.message ?? 'Silakan coba lagi'}';
      }

      _showErrorDialog('Login Gagal', errorMessage);
    } catch (e) {
      // Handle error yang tidak terduga
      _showErrorDialog('Error', 'Terjadi kesalahan yang tidak terduga: $e');
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // cek apakah user sudah login
    if (_boxLogin.get("loginStatus") ?? false) {
      return Home();
    }

    return Scaffold(
      // Membuat background warna biru
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Form(
        key: _formKey,
        // menggunakan scroll view agar form dapat di scroll
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              // Header aplikasi
              const SizedBox(height: 150),
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
                "Silahkan login terlebih dahulu",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 60),
              // Email field
              TextFormField(
                controller: _controllerEmail,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
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
                // validasi email yang lebih ketat
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  // Regex untuk validasi email
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodePassword.requestFocus(),
              ),
              const SizedBox(height: 10),
              // Password field
              TextFormField(
                controller: _controllerPassword,
                focusNode: _focusNodePassword,
                obscureText: _obscurePassword,
                enabled: !_isLoading,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        // mengubah status password untuk menampilkan password
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: _obscurePassword
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
                // validasi password
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
              const SizedBox(height: 60),
              // Tombol login
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // memanggil fungsi login atau menampilkan loading
                    onPressed: _isLoading ? null : login,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text("Login"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya account?"),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          _formKey.currentState?.reset();

                          // Navigasi ke halaman signup jika tombol "Daftar" ditekan
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const Signup();
                              },
                            ),
                          );
                        },
                        child: const Text("Daftar"),
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
    _focusNodePassword.dispose();

    // membuang controller agar tidak terjadi memory leak
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}