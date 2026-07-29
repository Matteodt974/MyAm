import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/child_profile.dart';
import '../../profile_allergies/data/allergy_local_store.dart';
import '../../profile_allergies/data/diet_local_store.dart';
import '../data/profile_share_repository.dart';
import 'child_profile_controller.dart';

class ChildProfileManagementSection extends ConsumerWidget {
  const ChildProfileManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profiles = ref.watch(childProfileControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profils familiaux',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        profiles.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Impossible de charger les profils : $error'),
              TextButton.icon(
                onPressed: () => ref.invalidate(childProfileControllerProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
          data: (state) => Column(
            children: [
              for (final profile in state.profiles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    profile.isChild ? Icons.child_care : Icons.person,
                  ),
                  title: Text(profile.displayName),
                  subtitle: profile.id == state.activeProfileId
                      ? const Text('Profil actif pour les scans')
                      : null,
                  trailing: profile.isChild
                      ? Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Afficher le code QR',
                              icon: const Icon(Icons.qr_code_2),
                              onPressed: () =>
                                  _showQrCode(context, ref, profile),
                            ),
                            IconButton(
                              tooltip: 'Modifier le nom',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _editProfile(context, ref, profile),
                            ),
                            IconButton(
                              tooltip: 'Supprimer le profil',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _deleteProfile(context, ref, profile),
                            ),
                          ],
                        )
                      : null,
                  onTap: () => ref
                      .read(childProfileControllerProvider.notifier)
                      .select(profile.id),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _createProfile(context, ref),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Ajouter un enfant'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showQrCode(
    BuildContext context,
    WidgetRef ref,
    ChildProfile profile,
  ) async {
    final allergies = await ref
        .read(allergyLocalStoreProvider)
        .load(profile.id, isParent: false);
    final diets = await ref
        .read(dietLocalStoreProvider)
        .load(profile.id, isParent: false);

    if (!context.mounted) return;

    // UC-28 etape 2 : le parent choisit la duree de validite du code.
    final validity = await _askForValidity(context);
    if (validity == null || !context.mounted) return;

    ProfileShare share;
    try {
      share = await ref
          .read(profileShareRepositoryProvider)
          .create(
            childId: profile.id,
            displayName: profile.displayName,
            allergies: allergies,
            diets: diets,
            validityDays: validity.days,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Partage impossible : $error')));
      return;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('QR de ${profile.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: QrImageView(
                  data: share.qrPayload,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Un autre utilisateur MyAM peut scanner ce code pour voir les '
                'allergies et régimes du profil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                share.expiresAt == null
                    ? 'Validité : illimitée.'
                    : 'Valide jusqu\'au ${_formatDate(share.expiresAt!)}.',
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Duree de validite proposee par le UC-28 : 1 jour, 7 jours ou illimitee.
  Future<({int? days})?> _askForValidity(BuildContext context) {
    return showModalBottomSheet<({int? days})>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Durée de validité du code',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('1 jour'),
              onTap: () => Navigator.pop(sheetContext, (days: 1)),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('7 jours'),
              onTap: () => Navigator.pop(sheetContext, (days: 7)),
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Illimitée'),
              subtitle: const Text('Révocable à tout moment'),
              onTap: () => Navigator.pop(sheetContext, (days: null)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final name = await _askForName(context, title: 'Nouveau profil enfant');
    if (name == null) return;

    try {
      await ref.read(childProfileControllerProvider.notifier).createChild(name);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Création impossible : $error')));
    }
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    ChildProfile profile,
  ) async {
    final name = await _askForName(
      context,
      title: 'Modifier le profil',
      initialValue: profile.displayName,
    );
    if (name == null) return;

    try {
      await ref
          .read(childProfileControllerProvider.notifier)
          .renameChild(profile.id, name);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modification impossible : $error')),
      );
    }
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    ChildProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le profil?'),
        content: Text(
          'Le profil de ${profile.displayName} sera supprimé définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(childProfileControllerProvider.notifier)
          .deleteChild(profile.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $error')),
      );
    }
  }

  Future<String?> _askForName(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) async {
    String name = initialValue;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: "Nom de l'enfant"),
          onChanged: (value) {
            name = value;
          },
          onFieldSubmitted: (value) {
            final trimmedName = value.trim();
            if (trimmedName.isNotEmpty) {
              Navigator.pop(dialogContext, trimmedName);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final trimmedName = name.trim();
              if (trimmedName.isNotEmpty) {
                Navigator.pop(dialogContext, trimmedName);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    return result;
  }
}
