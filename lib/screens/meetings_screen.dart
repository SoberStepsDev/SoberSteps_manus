import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'meetingsAndSupport'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: Text(S.t(context, 'meetingsIntro'),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            ),
            const SizedBox(height: 24),
            Text(S.t(context, 'findMeeting'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _MeetingCard(titleKey: 'aa', subtitleKey: 'aaDesc', url: 'https://www.aa.org/find-aa', icon: Icons.groups),
            _MeetingCard(titleKey: 'na', subtitleKey: 'naDesc', url: 'https://www.na.org/meetingsearch/', icon: Icons.groups),
            _MeetingCard(titleKey: 'smart', subtitleKey: 'smartDesc', url: 'https://www.smartrecovery.org/community/calendar.php', icon: Icons.psychology),
            _MeetingCard(titleKey: 'refuge', subtitleKey: 'refugeDesc', url: 'https://recoverydharma.org/meetings', icon: Icons.self_improvement),
            _MeetingCard(titleKey: 'itr', subtitleKey: 'itrDesc', url: 'https://www.intherooms.com', icon: Icons.computer),
            const SizedBox(height: 32),
            Text(S.t(context, 'crisisLines'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _PhoneCard(titleKey: 'samhsa', phone: '1-800-662-4357', subtitleKey: 'samhsaDesc'),
            _PhoneCard(titleKey: 'helpline', phone: '116 123', subtitleKey: 'helplineDesc'),
            _PhoneCard(titleKey: 'emergency', phone: '112', subtitleKey: 'emergencyDesc'),
            const SizedBox(height: 32),
            Text(S.t(context, 'tips'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _tipTile(context, 'tip1'),
            _tipTile(context, 'tip2'),
            _tipTile(context, 'tip3'),
            _tipTile(context, 'tip4'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _tipTile(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16)),
          Expanded(child: Text(S.t(context, key), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final String url;
  final IconData icon;

  const _MeetingCard({required this.titleKey, required this.subtitleKey, required this.url, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.t(context, titleKey), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(S.t(context, subtitleKey), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  final String titleKey;
  final String phone;
  final String subtitleKey;

  const _PhoneCard({required this.titleKey, required this.phone, required this.subtitleKey});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('tel:$phone')),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.crisisRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.crisisRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone, color: AppColors.crisisRed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.t(context, titleKey), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('$phone — ${S.t(context, subtitleKey)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
