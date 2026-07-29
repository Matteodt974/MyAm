import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'bristol_scale.dart';
import 'digestive_journal_controller.dart';

/// Ouvre le formulaire de saisie d'une entree du journal digestif (UC-23).
///
/// Renvoie `true` si une entree a ete enregistree.
Future<bool?> showDigestiveEntrySheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _DigestiveEntrySheet(),
  );
}

class _DigestiveEntrySheet extends ConsumerStatefulWidget {
  const _DigestiveEntrySheet();

  @override
  ConsumerState<_DigestiveEntrySheet> createState() =>
      _DigestiveEntrySheetState();
}

class _DigestiveEntrySheetState extends ConsumerState<_DigestiveEntrySheet> {
  final _notesController = TextEditingController();

  int? _selectedType;
  DateTime _occurredAt = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (!mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? _occurredAt.hour,
      time?.minute ?? _occurredAt.minute,
    );

    setState(() {
      // Le backend refuse une date future (@PastOrPresent).
      final capped = DateTime.now();
      _occurredAt = picked.isAfter(capped) ? capped : picked;
    });
  }

  Future<void> _save() async {
    final type = _selectedType;
    if (type == null || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(digestiveJournalControllerProvider.notifier)
          .addEntry(
            bristolType: type,
            occurredAt: _occurredAt,
            notes: _notesController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle entrée',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sélectionnez le type qui correspond le mieux à votre transit.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final type in bristolTypes)
                        _BristolOption(
                          type: type,
                          selected: _selectedType == type.value,
                          onTap: () =>
                              setState(() => _selectedType = type.value),
                        ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: const Text('Date et heure'),
                        subtitle: Text(
                          DateFormat.yMd('fr_CA').add_Hm().format(_occurredAt),
                        ),
                        trailing: TextButton(
                          onPressed: _saving ? null : _pickDateTime,
                          child: const Text('Modifier'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        maxLength: 1000,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optionnel)',
                          hintText: 'Ex. crampes, ballonnements…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selectedType == null || _saving
                          ? null
                          : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BristolOption extends StatelessWidget {
  const _BristolOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final BristolType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = bristolCategoryColors(colorScheme, type.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? colors.background : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.foreground : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          child: Text('${type.value}'),
        ),
        title: Text(
          type.label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: selected ? colors.foreground : null,
          ),
        ),
        subtitle: Text(
          type.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected ? colors.foreground : colorScheme.outline,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: colors.foreground)
            : null,
      ),
    );
  }
}
