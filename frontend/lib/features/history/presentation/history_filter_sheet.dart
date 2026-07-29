import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/scan_history_entry.dart';
import '../data/scan_history_repository.dart';

typedef ScanTypeChanged = void Function(ScanType type, bool selected);

typedef RiskLevelChanged = void Function(String level, bool selected);

/// Bottom sheet content used to filter the scan history.
///
/// The sheet is stateless from the outside; internal selections are handled by
/// a private stateful widget so callers can keep a `const` constructor.
class HistoryFilterSheet extends StatelessWidget {
  const HistoryFilterSheet({
    super.key,
    required this.availableAllergens,
    required this.onApply,
  });

  final List<String> availableAllergens;
  final ValueChanged<HistoryFilter> onApply;

  @override
  Widget build(BuildContext context) {
    return _HistoryFilterSheetContent(
      availableAllergens: availableAllergens,
      onApply: onApply,
    );
  }
}

class _HistoryFilterSheetContent extends StatefulWidget {
  const _HistoryFilterSheetContent({
    required this.availableAllergens,
    required this.onApply,
  });

  final List<String> availableAllergens;
  final ValueChanged<HistoryFilter> onApply;

  @override
  State<_HistoryFilterSheetContent> createState() =>
      _HistoryFilterSheetContentState();
}

class _HistoryFilterSheetContentState
    extends State<_HistoryFilterSheetContent> {
  DateTime? _from;
  DateTime? _to;
  final Set<ScanType> _selectedTypes = {};
  final Set<String> _selectedRiskLevels = {};
  String? _selectedAllergen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Filtres', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Période', style: theme.textTheme.titleSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Du'),
              trailing: TextButton(
                onPressed: () => _pickDate(isFrom: true),
                child: Text(
                  _from != null ? DateFormat.yMd('fr_CA').format(_from!) : '-',
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Au'),
              trailing: TextButton(
                onPressed: () => _pickDate(isFrom: false),
                child: Text(
                  _to != null ? DateFormat.yMd('fr_CA').format(_to!) : '-',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Type de scan', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ScanTypeChip(
                  label: 'Code-barres',
                  type: ScanType.barcode,
                  selected: _selectedTypes,
                  onChanged: _onTypeChanged,
                ),
                _ScanTypeChip(
                  label: 'Plat',
                  type: ScanType.dish,
                  selected: _selectedTypes,
                  onChanged: _onTypeChanged,
                ),
                _ScanTypeChip(
                  label: 'Étiquette',
                  type: ScanType.label,
                  selected: _selectedTypes,
                  onChanged: _onTypeChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Résultat', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RiskChip(
                  label: 'Danger',
                  level: 'DANGER',
                  selected: _selectedRiskLevels,
                  onChanged: _onRiskChanged,
                ),
                _RiskChip(
                  label: 'Attention',
                  level: 'WARNING',
                  selected: _selectedRiskLevels,
                  onChanged: _onRiskChanged,
                ),
                _RiskChip(
                  label: 'Sûr',
                  level: 'SAFE',
                  selected: _selectedRiskLevels,
                  onChanged: _onRiskChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _selectedAllergen,
              decoration: const InputDecoration(labelText: 'Allergène'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                for (final allergen in widget.availableAllergens)
                  DropdownMenuItem(value: allergen, child: Text(allergen)),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAllergen = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: const Text('Réinitialiser'),
                ),
                const Spacer(),
                FilledButton(onPressed: _apply, child: const Text('Appliquer')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  void _onTypeChanged(ScanType type, bool selected) {
    setState(() {
      if (selected) {
        _selectedTypes.add(type);
      } else {
        _selectedTypes.remove(type);
      }
    });
  }

  void _onRiskChanged(String level, bool selected) {
    setState(() {
      if (selected) {
        _selectedRiskLevels.add(level);
      } else {
        _selectedRiskLevels.remove(level);
      }
    });
  }

  void _reset() {
    setState(() {
      _from = null;
      _to = null;
      _selectedTypes.clear();
      _selectedRiskLevels.clear();
      _selectedAllergen = null;
    });
  }

  void _apply() {
    widget.onApply(
      HistoryFilter(
        from: _from,
        to: _to,
        types: _selectedTypes.isEmpty ? null : _selectedTypes.toList(),
        riskLevels: _selectedRiskLevels.isEmpty
            ? null
            : _selectedRiskLevels.toList(),
        allergen: _selectedAllergen,
      ),
    );
  }
}

class _ScanTypeChip extends StatelessWidget {
  const _ScanTypeChip({
    required this.label,
    required this.type,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final ScanType type;
  final Set<ScanType> selected;
  final ScanTypeChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected.contains(type),
      onSelected: (value) => onChanged(type, value),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({
    required this.label,
    required this.level,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String level;
  final Set<String> selected;
  final RiskLevelChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected.contains(level),
      onSelected: (value) => onChanged(level, value),
    );
  }
}
