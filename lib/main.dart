import 'package:flutter/material.dart';
import 'package:hunter_demo/repositories/app_repositories.dart';
import 'package:hunter_demo/screens/login_screen.dart';
import 'package:hunter_demo/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los catálogos/datos de referencia desde el repositorio (hoy: mock).
  await Repositories.bootstrap();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hunter Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
