import 'package:attendance_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loginscreen.dart';

class LogOutScreen extends StatefulWidget {
  const LogOutScreen({super.key});

  @override
  State<LogOutScreen> createState() => _LogOutScreenState();
}

class _LogOutScreenState extends State<LogOutScreen> {
  @override
  void initState() {
    super.initState();
    _logout();
  }

  // Future<void> _logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear(); // Clear saved login info
  //
  //   await Future.delayed(const Duration(seconds: 1)); // Optional: Wait briefly
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (_) => const LoginScreen()),
  //   );
  // }

  Future<void> _logout() async {
    final authService = AuthService();
    await authService.logout(); // use AuthService to handle logout

    await Future.delayed(const Duration(seconds: 1)); // Optional wait for UX
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   SystemChrome.setSystemUIOverlayStyle(
  //     const SystemUiOverlayStyle(
  //       statusBarColor: Colors.transparent,
  //       statusBarIconBrightness: Brightness.light,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(), // While logging out
        ),
    );
  }
}
