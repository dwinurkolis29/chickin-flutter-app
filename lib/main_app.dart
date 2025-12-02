import 'package:flutter/material.dart';

import 'features/auth/presentation/login.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          /// The seed color is a dark blue color.
          seedColor: const Color.fromRGBO(32, 63, 129, 1.0),
        ),
      ),
      /// The home of the application is the Login widget.
      home: const Login(),
    );
  }
}
