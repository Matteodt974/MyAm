import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scan_history_entry.dart';
import '../data/scan_history_repository.dart';
import 'history_controller.dart';
import 'history_detail_sheet.dart';
import 'history_filter_sheet.dart';
import 'history_list_tile.dart';

/// Screen that lists every scan saved in the local history.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer',
            onPressed: () => _openFilterSheet(context, ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
            onSelected: (value) => _onMenuSelected(context, ref, value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Exporter CSV')),
              PopupMenuItem(value: 'clear', child: Text('Vider l\'historique')),
            ],
          ),
        ],
      ),
      body: _buildBody(context, ref, state, colorScheme, theme.textTheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ScanHistoryEntry>> state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(child: Text('Erreur: ${state.error}'));
    }

    final entries = state.value ?? [];

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Aucune numérisation enregistrée.',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return HistoryListTile(
          entry: entry,
          onTap: () => _openDetailSheet(context, entry),
        );
      },
    );
  }

  Future<void> _openFilterSheet(BuildContext context, WidgetRef ref) async {
    // Always drawn from the full history, not the currently filtered view,
    // so applying a filter doesn't shrink the options available afterward.
    final allEntries = await ref.read(scanHistoryRepositoryProvider).load();
    final availableAllergens =
        allEntries.expand((e) => e.matchedAllergens).toSet().toList()..sort();

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HistoryFilterSheet(
        availableAllergens: availableAllergens,
        onApply: (filter) {
          Navigator.of(context).pop();
          ref.read(historyControllerProvider.notifier).applyFilter(filter);
        },
      ),
    );
  }

  void _openDetailSheet(BuildContext context, ScanHistoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HistoryDetailSheet(entry: entry),
    );
  }

  Future<void> _onMenuSelected(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    if (value == 'export') {
      await ref.read(historyControllerProvider.notifier).exportCsv();
      return;
    }

    if (value == 'clear') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Vider l\'historique'),
          content: const Text(
            'Voulez-vous vraiment supprimer toutes les numérisations enregistrées ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Vider'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(historyControllerProvider.notifier).clearAll();
      }
    }
  }
}
