import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
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

  final Box _boxAccounts = Hive.box("accounts");
  final FirebaseService _firebaseService = FirebaseService();

  // membuat variabel untuk menyimpan password visibility
  bool _obscurePassword = true;

  // membuat method untuk signup
  void signup() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        // Create Firebase Auth user
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _controllerEmail.text,
          password: _controllerPassword.text,
        );

        // Get UID from created user
        final uid = userCredential.user!.uid;

        // Menyimpan email dan password ke Hive box
        _boxAccounts.put(
          _controllerEmail.text,
          _controllerConFirmPassword.text,
        );

        // Create user profile
        final profile = UserProfile(
          name: _controllerUsername.text,
          phone: _controllerPhone.text,
          address: _controllerAddress.text,
        );

        // Create default cage data (empty for now)
        const cage = CageData();

        // Create user document in Firestore with new structure
        await _firebaseService.createUserDocument(uid, profile, cage);

        // AUTO-CREATE: Buat periode pertama otomatis
        final firstPeriod = PeriodData(
          name: 'Periode 1',
          initialCapacity: cage.capacity > 0 ? cage.capacity : 1000, // Default 1000 jika cage belum diisi
          initialWeight: 0.4, // Default DOC weight in kg
          startDate: DateTime.now(),
          status: 'active',
          createdAt: DateTime.now(),
        );
        await _firebaseService.createPeriod(firstPeriod);

        // Menampilkan snackbar sukses
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              width: 200,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              behavior: SnackBarBehavior.floating,
              content: const Text("Registrasi Sukses"),
            ),
          );

          _formKey.currentState?.reset();
          // Return email dan password ke login page
          Navigator.pop(context, {
            'email': _controllerEmail.text,
            'password': _controllerPassword.text,
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat registrasi';
      
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
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
                // melakukan validasi email tidak boleh kosong
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Masukkan email.";
                    // melakukan validasi email harus valid
                  } else if (!(value.contains('@') && value.contains('.'))) {
                    return "Email tidak valid.";
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
                    onPressed: signup,
                    child: const Text("Register"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sudah punya akun?"),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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
