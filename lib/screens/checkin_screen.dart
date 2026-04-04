import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../providers/journal_provider.dart';
import '../constants/app_constants.dart';
import '../l10n/strings.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  int _mood = 3;
  double _craving = 0;
  final Set<String> _triggers = {};
  final _noteController = TextEditingController();
  bool _saving = false;
  bool _showSearch = false;
  final _searchController = TextEditingController();

  static const _moodEmojis = ['😔', '😕', '😐', '🙂', '😄'];

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final scaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(S.t(context, 'checkin')),
        ),
        actions: [
          Tooltip(
            message: S.t(context, 'journalSearchTooltip'),
            child: Semantics(
              label: S.t(context, 'journalSearchTooltip'),
              button: true,
              child: IconButton(
                icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      journal.setSearchQuery('');
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showSearch) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: journal.setSearchQuery,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: S.t(context, 'journalSearchHint'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Text(
                  S.t(context, 'journalNotesForToday'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              SizedBox(
                height: scaler.scale(180).clamp(120.0, 320.0),
                child: journal.filteredEntries.isEmpty
                    ? Center(
                        child: Text(
                          journal.entries.isEmpty
                              ? S.t(context, 'doCheckinToSee')
                              : journal.searchQuery.trim().isEmpty
                                  ? S.t(context, 'doCheckinToSee')
                                  : S.t(context, 'journalNoNoteMatches'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: journal.filteredEntries.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.surfaceLight),
                        itemBuilder: (context, i) {
                          final e = journal.filteredEntries[i];
                          final note = e.note?.trim();
                          final preview = (note == null || note.isEmpty) ? '—' : note;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              preview,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              '${e.createdAt.day}.${e.createdAt.month}.${e.createdAt.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
              ),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.t(context, 'howDoYouFeel'), style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildMoodPicker(),
                    const SizedBox(height: 32),
                    Text(S.t(context, 'cravingLevel'), style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildCravingSlider(),
                    const SizedBox(height: 32),
                    Text(S.t(context, 'triggers'), style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildTriggerChips(),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _noteController,
                      maxLength: AppConstants.maxNoteLength,
                      maxLines: 4,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(hintText: S.t(context, 'gratefulToday')),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _save();
                              },
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(S.t(context, 'saveCheckin')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final selected = _mood == i + 1;
        return GestureDetector(
          onTap: () => setState(() => _mood = i + 1),
          child: AnimatedScale(
            scale: selected ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              _moodEmojis[i],
              style: TextStyle(fontSize: 40, color: selected ? null : AppColors.textPrimary.withValues(alpha: 0.5)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCravingSlider() {
    final color = Color.lerp(AppColors.success, AppColors.error, _craving / 10)!;
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: AppColors.surfaceLight,
            trackHeight: 6,
          ),
          child: Slider(
            value: _craving,
            min: 0,
            max: 10,
            divisions: 10,
            label: _craving.round().toString(),
            onChanged: (v) => setState(() => _craving = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.t(context, 'scale0'), style: Theme.of(context).textTheme.bodySmall),
            Text(S.t(context, 'scale10'), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggerChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.defaultTriggers.map((t) {
        final selected = _triggers.contains(t);
        return FilterChip(
          label: Text(S.t(context, 'trigger_$t')),
          selected: selected,
          selectedColor: AppColors.primary.withValues(alpha: 0.3),
          checkmarkColor: AppColors.primary,
          backgroundColor: AppColors.surfaceLight,
          labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
          onSelected: (v) {
            setState(() {
              if (v) {
                _triggers.add(t);
              } else {
                _triggers.remove(t);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final journal = context.read<JournalProvider>();
    final result = await journal.saveCheckin(
      mood: _mood,
      cravingLevel: _craving.round(),
      triggers: _triggers.toList(),
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    setState(() => _saving = false);

    if (!mounted) return;
    if (result == 'offline') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'savedOffline'))));
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      return;
    }

    _showReaction();
  }

  void _showReaction() {
    final note = _noteController.text.toLowerCase();
    final gratitudeWords = ['wdzięczny', 'grateful', 'thankful', 'dziękuję', 'dziekuje'];
    final hasGratitude = gratitudeWords.any((w) => note.contains(w));
    final consecutive = context.read<JournalProvider>().consecutiveCheckins;

    String message;
    IconData icon;
    Color color;

    if (_mood <= 2) {
      message = S.t(context, 'checkinReactHard');
      icon = Icons.local_fire_department;
      color = AppColors.gold;
    } else if (_craving > 7) {
      message = S.t(context, 'checkinReactWave');
      icon = Icons.waves;
      color = AppColors.primary;
    } else if (_triggers.contains('loneliness')) {
      message = S.t(context, 'checkinReactLonely');
      icon = Icons.local_fire_department;
      color = AppColors.gold;
    } else if (_mood >= 4 && _craving < 4) {
      message = S.t(context, 'checkinReactYours');
      icon = Icons.celebration;
      color = AppColors.gold;
    } else if (hasGratitude) {
      message = S.t(context, 'checkinReactGratitude');
      icon = Icons.auto_awesome;
      color = AppColors.gold;
    } else if (consecutive == 3) {
      message = S.t(context, 'checkinReact3days');
      icon = Icons.auto_awesome;
      color = AppColors.primary;
    } else {
      message = S.t(context, 'checkinReactSaved');
      icon = Icons.check_circle;
      color = AppColors.success;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color).animate().scale(begin: const Offset(0.3, 0.3), duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(S.t(context, 'ok')))],
      ),
    );
  }
}
