import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme.dart';
import '../constants/app_constants.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/sobriety_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';

/// ProfileScreen — 8 sections per spec Faza 9.2.
/// Philosophy: no dark patterns, honest signout, SAMHSA always visible.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifEnabled = true;
  int _reminderHour = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
    AnalyticsService().track(AnalyticsService.eProfileOpened);
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifEnabled = prefs.getBool('notif_enabled') ?? true;
      _reminderHour = prefs.getInt('checkin_reminder_hour') ?? 20;
    });
  }

  Future<void> _toggleNotif(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', val);
    final ns = NotificationService();
    if (val) {
      await ns.scheduleCheckinReminder(_reminderHour);
    } else {
      await ns.cancelCheckinReminder();
    }
    setState(() => _notifEnabled = val);
    AnalyticsService().track('notification_toggled', {'enabled': val});
  }

  Future<void> _changeReminderHour(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SizedBox(
        height: 300,
        child: ListView.builder(
          itemCount: 24,
          itemBuilder: (_, i) => ListTile(
            title: Text('${i.toString().padLeft(2, '0')}:00',
                style: TextStyle(color: i == _reminderHour ? AppColors.primary : AppColors.textPrimary)),
            trailing: i == _reminderHour ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () => Navigator.pop(ctx, i),
          ),
        ),
      ),
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('checkin_reminder_hour', picked);
    await NotificationService().scheduleCheckinReminder(picked);
    setState(() => _reminderHour = picked);
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Wylogować się?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Twoje dane są bezpieczne — możesz wrócić w każdej chwili.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Zostań')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wyloguj', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await auth.signOut();
      if (context.mounted) Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocaleProvider>();
    final sobriety = context.watch<SobrietyProvider>();
    final purchase = context.watch<PurchaseProvider>();
    final isPro = purchase.isPro;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'profile')), backgroundColor: AppColors.background),
      body: Column(
        children: [
          // SAMHSA banner — non-dismissible, always visible (spec requirement)
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('tel:1-800-662-4357')),
            child: Container(
              width: double.infinity,
              color: AppColors.crisisRed.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(children: [
                Icon(Icons.phone, color: AppColors.crisisRed, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Kryzys? SAMHSA: 1-800-662-4357 (24/7)',
                    style: TextStyle(color: AppColors.crisisRed, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, auth, sobriety, isPro),
                const SizedBox(height: 20),
                if (!isPro) _tile(context, Icons.star, S.t(context, 'recoveryPlus'),
                    () => Navigator.pushNamed(context, '/paywall'), color: AppColors.gold),
                if (isPro) _tile(context, Icons.subscriptions_outlined, S.t(context, 'subscriptionTitle'),
                    () => Navigator.pushNamed(context, '/subscription')),
                _SectionLabel(S.t(context, 'sobriety')),
                _tile(context, Icons.calendar_today, S.t(context, 'changeSobrietyDate'),
                    () => _showDatePicker(context, sobriety)),
                _SectionLabel(S.t(context, 'tools')),
                _tile(context, Icons.savings_rounded, S.t(context, 'savingsHealth'),
                    () => Navigator.pushNamed(context, '/savings')),
                _tile(context, Icons.bar_chart_rounded, S.t(context, 'triggerAnalysis'),
                    () => Navigator.pushNamed(context, '/triggers')),
                _tile(context, Icons.school_rounded, S.t(context, 'miniLessons'),
                    () => Navigator.pushNamed(context, '/lessons')),
                _tile(context, Icons.map_rounded, S.t(context, 'meetings'),
                    () => Navigator.pushNamed(context, '/meetings')),
                _tile(context, Icons.auto_awesome_outlined, S.t(context, 'returnToSelf'),
                    () => Navigator.pushNamed(context, '/return-to-self')),
                _tile(context, Icons.people_alt_rounded, S.t(context, 'accountabilityPartner'),
                    () => Navigator.pushNamed(context, '/accountability'),
                    badge: isPro ? null : 'PRO'),
                _tile(context, Icons.mail_outline, S.t(context, 'lettersToSelf'),
                    () => Navigator.pushNamed(context, '/future-letter-list')),
                _tile(context, Icons.waves, S.t(context, 'cravingSurf'),
                    () => Navigator.pushNamed(context, '/craving-surf')),
                _tile(context, Icons.auto_stories_rounded, S.t(context, 'crashLogTitle'),
                    () => Navigator.pushNamed(context, '/crash-log')),
                _SectionLabel(S.t(context, 'notifications')),
                _switchTile('Przypomnienie o check-inie', Icons.notifications_outlined,
                    _notifEnabled, _toggleNotif),
                if (_notifEnabled) _tile(context, Icons.access_time,
                    'Godzina: ${_reminderHour.toString().padLeft(2, '0')}:00',
                    () => _changeReminderHour(context)),
                _SectionLabel(S.t(context, 'settings')),
                _tile(context, Icons.language, S.t(context, 'language'),
                    () => _showLocalePicker(context, loc)),
                _SectionLabel(S.t(context, 'info')),
                _tile(context, Icons.person_outline, S.t(context, 'aboutCreator'),
                    () => _showAboutCreator(context)),
                _tile(context, Icons.description_outlined, S.t(context, 'terms'),
                    () => launchUrl(Uri.parse(AppConstants.termsUrl))),
                _tile(context, Icons.privacy_tip_outlined, S.t(context, 'privacy'),
                    () => launchUrl(Uri.parse(AppConstants.privacyUrl))),
                _tile(context, Icons.email_outlined, S.t(context, 'contactEmail'),
                    () => launchUrl(Uri.parse('mailto:${AppConstants.contactEmail}'))),
                if (auth.isLoggedIn) ...[
                  _SectionLabel(S.t(context, 'account')),
                  _tile(context, Icons.restore, S.t(context, 'restorePurchases'),
                      () => purchase.restore()),
                  _tile(context, Icons.delete_forever_outlined, S.t(context, 'deleteAccount'),
                      () => launchUrl(Uri.parse(
                          'mailto:${AppConstants.contactEmail}?subject=Usunięcie%20konta%20-%20SoberSteps')),
                      color: AppColors.textSecondary),
                  _tile(context, Icons.logout, S.t(context, 'logout'),
                      () => _confirmSignOut(context, auth), color: AppColors.error),
                ],
                if (!auth.isLoggedIn) ...[
                  _tile(context, Icons.login, S.t(context, 'login'),
                      () => Navigator.pushNamed(context, '/auth')),
                  _tile(context, Icons.person_add, S.t(context, 'register'),
                      () => Navigator.pushNamed(context, '/register')),
                ],
                const SizedBox(height: 32),
                Center(child: Text(S.t(context, 'version'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, SobrietyProvider sobriety, bool isPro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: isPro ? AppColors.gold : AppColors.primary,
          child: Icon(isPro ? Icons.shield : Icons.person, size: 36, color: AppColors.background),
        ),
        const SizedBox(height: 12),
        Text(auth.user?.email ?? S.t(context, 'guest'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('${sobriety.daysSober} ${S.t(context, 'daysSober')}',
            style: const TextStyle(color: AppColors.textSecondary)),
        if (isPro) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Text('Recovery+',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ]),
    );
  }

  static Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color? color, String? badge}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(badge,
                style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ]),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static Widget _switchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showAboutCreator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: const [
            Text('O Twórcy', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 16),
            Text(
              'SoberSteps powstał z osobistego doświadczenia — nie z laboratorium.\n\n'
              'Aplikacja opiera się na trzech filarach:\n'
              '• Uśmiech — łagodność wobec siebie\n'
              '• Perspektywa — dystans do myśli\n'
              '• Droga — jeden krok na raz\n\n'
              'Nie jesteś projektem do naprawienia. Jesteś człowiekiem w drodze.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 20),
            Divider(color: AppColors.surface),
            SizedBox(height: 12),
            Text('About the Creator', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('SoberSteps was built from personal experience.\nSmile · Perspective · Path.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
            SizedBox(height: 12),
            Text('Sobre el Creador', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('SoberSteps nació de la experiencia personal.\nSonrisa · Perspectiva · Camino.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
            SizedBox(height: 12),
            Text('Over de Maker', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('SoberSteps is gebouwd vanuit persoonlijke ervaring.\nGlimlach · Perspectief · Weg.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLocalePicker(BuildContext context, LocaleProvider loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['en', 'pl', 'es', 'fr', 'ru', 'nl'].map((code) {
            final names = {'en': 'English', 'pl': 'Polski', 'es': 'Español', 'fr': 'Français', 'ru': 'Русский', 'nl': 'Nederlands'};
            return ListTile(
              title: Text(names[code] ?? code, style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () { loc.setLocale(Locale(code)); Navigator.pop(ctx); },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, SobrietyProvider sobriety) async {
    final date = await showDatePicker(
      context: context,
      initialDate: sobriety.sobrietyStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (date != null) await sobriety.setSobrietyStartDate(date);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
  );
}
