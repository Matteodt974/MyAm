import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/digestive_entry.dart';
import 'bristol_scale.dart';
import 'consent_controller.dart';
import 'consent_screen.dart';
import 'digestive_entry_sheet.dart';
import 'digestive_journal_controller.dart';

/// Journal digestif (UC-23) : liste des entrees et saisie d'un nouvel episode.
///
/// L'ecran est verrouille tant que le consentement specifique n'a pas ete
/// donne : ce sont des donnees de sante (Loi 25 / RGPD).
class DigestiveJournalScreen extends ConsumerStatefulWidget {
  const DigestiveJournalScreen({super.key});

  @override
  ConsumerState<DigestiveJournalScreen> createState() =>
      _DigestiveJournalScreenState();
}

class _DigestiveJournalScreenState
    extends ConsumerState<DigestiveJournalScreen> {
  bool _consentPromptShown = false;

  /// Ouvre le dialogue de consentement au premier affichage si l'utilisateur
  /// n'a encore jamais tranche.
  void _promptConsentIfNeeded(ConsentDecision decision) {
    if (decision != ConsentDecision.undecided || _consentPromptShown) return;
    _consentPromptShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showConsentDialog(context);
    });
  }

  Future<void> _reviewConsent() async {
    await showConsentDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final consentAsync = ref.watch(consentControllerProvider);
    final granted = consentAsync.maybeWhen(
      data: (decision) => decision == ConsentDecision.granted,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Journal digestif')),
      floatingActionButton: granted
          ? FloatingActionButton.extended(
              onPressed: () => showDigestiveEntrySheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            )
          : null,
      body: consentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (decision) {
          _promptConsentIfNeeded(decision);

          if (decision != ConsentDecision.granted) {
            return _ConsentRequired(onReview: _reviewConsent);
          }
          return const _EntriesList();
        },
      ),
    );
  }
}

class _ConsentRequired extends StatelessWidget {
  const _ConsentRequired({required this.onReview});

  final Future<void> Function() onReview;

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
            Text(
              'Consentement requis',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Le journal digestif enregistre des données de santé. Votre '
              'consentement explicite est nécessaire avant toute saisie.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onReview,
              child: const Text('Revoir le consentement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntriesList extends ConsumerWidget {
  const _EntriesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(digestiveJournalControllerProvider);
    final theme = Theme.of(context);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erreur : $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref
                    .read(digestiveJournalControllerProvider.notifier)
                    .refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune entrée pour le moment.',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez au moins une entrée pour pouvoir lancer '
                    'l’analyse des tendances.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/analysis'),
                    icon: const Icon(Icons.insights),
                    label: const Text('Analyse des tendances'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(digestiveJournalControllerProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: entries.length,
            itemBuilder: (context, index) => _EntryTile(entry: entries[index]),
          ),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final DigestiveEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = bristolTypeFor(entry.bristolType);
    final category = type?.category ?? BristolCategory.normal;
    final colors = bristolCategoryColors(theme.colorScheme, category);
    final notes = entry.notes;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          child: Text('${entry.bristolType}'),
        ),
        title: Text(type?.description ?? 'Type ${entry.bristolType}'),
        subtitle: Text(
          DateFormat.yMd('fr_CA').add_Hm().format(entry.occurredAt.toLocal()),
        ),
        trailing: Chip(
          label: Text(
            bristolCategoryLabel(category),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.foreground,
            ),
          ),
          backgroundColor: colors.background,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        isThreeLine: notes != null && notes.isNotEmpty,
        onTap: notes == null || notes.isEmpty
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(type?.label ?? 'Type ${entry.bristolType}'),
                  content: Text(notes),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
