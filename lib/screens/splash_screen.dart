import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _statusText = 'Starting ParkSpot...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);

    Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _statusText = 'Connecting to server...');
    });

    Timer(const Duration(seconds: 3), () => _go());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_go);
    });
  }

  void _go() {
    if (_navigated || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.loading) {
      _navigated = true;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    try { context.read<AuthProvider>().removeListener(_go); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF065F46),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))]),
                child: const Icon(Icons.local_parking, size: 70, color: Color(0xFF059669)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('ParkSpot', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('Find Perfect Parking for Your Events',
              style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 0.5)),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
              ),
            ),
            const SizedBox(height: 16),
            Text(_statusText, style: const TextStyle(fontSize: 13, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
