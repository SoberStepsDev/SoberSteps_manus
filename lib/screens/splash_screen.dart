import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/sobriety_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final sobriety = context.read<SobrietyProvider>();
      await sobriety.loadFromLocal();

      final prefs = await SharedPreferences.getInstance();
      final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;
      final onboarded = prefs.getBool('onboarding_complete') ?? false;

      if (!mounted) return;
      if (!disclaimerAccepted) {
        Navigator.of(context).pushReplacementNamed('/disclaimer');
      } else if (!onboarded) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else if (auth.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/SoberStepsLogo.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.local_fire_department_rounded, size: 80, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 24),
            Text('SoberSteps', style: Theme.of(context).textTheme.headlineLarge),
          ],
        ),
      ),
    );
  }
}
