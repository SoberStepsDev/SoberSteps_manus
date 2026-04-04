import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/theme.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../services/data_export_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'exportDataLoginRequired'))));
      return;
    }
    setState(() => _exporting = true);
    try {
      final file = await DataExportService().exportToJsonFile();
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: S.t(context, 'exportMyData'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'exportDataSuccess'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'exportDataError'))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(S.t(context, 'privacyTitle')),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.t(context, 'privacySubtitle'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(S.t(context, 'privacyUpdated'), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (auth.isLoggedIn) ...[
              Semantics(
                button: true,
                label: S.t(context, 'exportMyData'),
                child: ElevatedButton(
                  onPressed: _exporting ? null : _export,
                  child: _exporting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(S.t(context, 'exportMyData')),
                ),
              ),
              const SizedBox(height: 8),
              Text(S.t(context, 'exportDataPreparing'), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
            ],
            Text(S.t(context, 'privacyIntro'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
            const SizedBox(height: 24),
            for (int i = 1; i <= 11; i++) _Section(content: S.t(context, 'privacyS$i')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String content;

  const _Section({required this.content});

  @override
  Widget build(BuildContext context) {
    final parts = content.split('\n\n');
    final title = parts.isNotEmpty ? parts[0] : '';
    final body = parts.length > 1 ? parts.sublist(1).join('\n\n') : '';
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
