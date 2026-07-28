import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../digestive_journal/presentation/bristol_scale.dart';
import '../../digestive_journal/presentation/consent_controller.dart';
import '../../digestive_journal/presentation/consent_screen.dart';
import '../data/intolerance_report.dart';
import 'analysis_controller.dart';
import 'analysis_report_share.dart';

/// Analyse des tendances digestives (UC-26).
///
/// Preconditions verifiees ici : consentement accorde, au moins une entree de
/// journal digestif (verifiee cote serveur) et un journal alimentaire suffisant
/// sur 72 h (verifie cote serveur egalement).
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(consentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analyse des tendances')),
      body: consentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (decision) => decision == ConsentDecision.granted
            ? const _AnalysisBody()
            : _ConsentRequired(onReview: () => showConsentDialog(context)),
      ),
    );
  }
}

class _ConsentRequired extends StatelessWidget {
  const _ConsentRequired({required this.onReview});

  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Consentement requis', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Cette analyse croise vos données de santé avec vos scans '
              'récents. Votre consentement explicite est nécessaire.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onReview,
              child: const Text('Donner mon consentement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisBody extends ConsumerWidget {
  const _AnalysisBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(analysisControllerProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: '$e'),
      data: (report) =>
          report == null ? const _InitialState() : _ReportView(report: report),
    );
  }
}

class _InitialState extends ConsumerWidget {
  const _InitialState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.insights, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Déduire une intolérance potentielle',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'L’analyse croise les entrées de votre journal digestif avec les '
          'produits que vous avez scannés au cours des 72 dernières heures, '
          'afin de repérer des carences probables et un irritant alimentaire '
          'possible.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () =>
              ref.read(analysisControllerProvider.notifier).runAnalysis(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Lancer l’analyse'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/digestive-journal'),
          icon: const Icon(Icons.event_note),
          label: const Text('Ouvrir le journal digestif'),
        ),
      ],
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  ref.read(analysisControllerProvider.notifier).runAnalysis(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportView extends ConsumerWidget {
  const _ReportView({required this.report});

  final IntoleranceReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (report.status != IntoleranceStatus.ok) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _UnavailableCard(report: report),
          const SizedBox(height: 16),
          _DisclaimerCard(text: report.medicalDisclaimer),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () =>
                ref.read(analysisControllerProvider.notifier).runAnalysis(),
            child: const Text('Relancer l’analyse'),
          ),
        ],
      );
    }

    final summary = report.bristolSummary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (summary != null) ...[
          Text('Profil digestif', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _BristolSummaryCard(summary: summary),
          const SizedBox(height: 24),
        ],
        Text('Carences probables', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (report.probableDeficiencies.isEmpty)
          _InfoTile(
            icon: Icons.check_circle_outline,
            text: 'Aucune carence signalée.',
          )
        else
          for (final deficiency in report.probableDeficiencies)
            _InfoTile(icon: Icons.info_outline, text: deficiency),
        const SizedBox(height: 24),
        Text(
          'Irritants alimentaires possibles',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (report.possibleIrritants.isEmpty)
          _InfoTile(
            icon: Icons.check_circle_outline,
            text: 'Aucun irritant identifié parmi vos scans récents.',
          )
        else
          for (final irritant in report.possibleIrritants)
            _IrritantTile(irritant: irritant),
        const SizedBox(height: 24),
        _DisclaimerCard(text: report.medicalDisclaimer),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => shareIntoleranceReport(report),
          icon: const Icon(Icons.share),
          label: const Text('Partager le rapport'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () =>
              ref.read(analysisControllerProvider.notifier).runAnalysis(),
          child: const Text('Relancer l’analyse'),
        ),
      ],
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.report});

  final IntoleranceReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsJournalEntry =
        report.status == IntoleranceStatus.noJournalEntries;

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  needsJournalEntry
                      ? Icons.event_note_outlined
                      : Icons.hourglass_empty,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    needsJournalEntry
                        ? 'Journal digestif vide'
                        : 'Données alimentaires insuffisantes',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.message ?? 'Analyse non disponible pour le moment.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (needsJournalEntry)
              FilledButton.icon(
                onPressed: () => context.push('/digestive-journal'),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une entrée'),
              )
            else
              Text(
                'Scannez les produits que vous consommez : ils alimentent '
                'automatiquement le journal alimentaire.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BristolSummaryCard extends StatelessWidget {
  const _BristolSummaryCard({required this.summary});

  final BristolSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedTypes = summary.typeCounts.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dominantProfileLabel(summary.dominantProfile),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.entryCount} épisode(s) analysé(s)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in sortedTypes)
                  _TypeCountChip(
                    bristolType: type,
                    count: summary.typeCounts[type] ?? 0,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCountChip extends StatelessWidget {
  const _TypeCountChip({required this.bristolType, required this.count});

  final int bristolType;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category =
        bristolTypeFor(bristolType)?.category ?? BristolCategory.normal;
    final colors = bristolCategoryColors(theme.colorScheme, category);

    return Chip(
      backgroundColor: colors.background,
      label: Text(
        'Type $bristolType × $count',
        style: theme.textTheme.labelMedium?.copyWith(color: colors.foreground),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _IrritantTile extends StatelessWidget {
  const _IrritantTile({required this.irritant});

  final IrritantSuggestion irritant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastConsumedAt = irritant.lastConsumedAt;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.restaurant_menu,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(irritant.foodName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${irritant.episodesPreceded} épisode(s) précédé(s) par cet '
              'aliment',
            ),
            if (lastConsumedAt != null)
              Text(
                'Dernière consommation : '
                '${DateFormat.yMd('fr_CA').add_Hm().format(lastConsumedAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            if (irritant.allergens.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final allergen in irritant.allergens)
                      Chip(
                        label: Text(
                          allergen,
                          style: theme.textTheme.labelSmall,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

/// Rappel medical, toujours affiche avec un rapport (exigence du UC-26).
class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.medical_information_outlined,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text.isEmpty
                    ? 'Ces suggestions ne remplacent pas un avis médical. '
                          'Consultez un médecin ou un(e) diététiste avant tout '
                          'changement d’alimentation.'
                    : text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
