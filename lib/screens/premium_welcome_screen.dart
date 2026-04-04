import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

class PremiumWelcomeScreen extends StatefulWidget {
  const PremiumWelcomeScreen({super.key});

  @override
  State<PremiumWelcomeScreen> createState() => _PremiumWelcomeScreenState();
}

class _PremiumWelcomeScreenState extends State<PremiumWelcomeScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPage(
              icon: Icons.shield_rounded,
              color: AppColors.streakBlue,
              title: 'Witaj w Recovery+!',
              subtitle: 'Streak Protection włączony.',
            ),
            _buildPage(
              icon: Icons.mail_rounded,
              color: AppColors.primary,
              title: 'Napisz pierwszy list do przyszłego siebie.',
              subtitle: 'Dotrze do Ciebie w wybranym dniu.',
              ctaLabel: 'Napisz list',
              ctaRoute: '/future-letter-write',
            ),
            _buildPage(
              icon: Icons.mic_rounded,
              color: AppColors.gold,
              title: 'Przygotuj się na głos w Dniu 30.',
              subtitle: 'Wiadomość głosowa czeka na Twój milestone.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? ctaLabel,
    String? ctaRoute,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color).animate().scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 48),
          if (ctaLabel != null && ctaRoute != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pushNamed(ctaRoute),
                child: Text(ctaLabel),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_page < 2 ? 'Dalej' : 'Zaczynajmy!'),
            ),
          ),
        ],
      ),
    );
  }
}
