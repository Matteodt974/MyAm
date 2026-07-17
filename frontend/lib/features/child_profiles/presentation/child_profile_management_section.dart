import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/child_profile.dart';
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
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: "Nom de l'enfant"),
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) Navigator.pop(dialogContext, name);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.pop(dialogContext, name);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
