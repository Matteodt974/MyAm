import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/languages.dart';
import 'allergy_controller.dart';
import 'language_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text;

    if (text.trim().isEmpty) return;

    await ref.read(allergyControllerProvider.notifier).add(text);

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final allergiesAsync = ref.watch(allergyControllerProvider);

    final languageAsync = ref.watch(languageControllerProvider);

    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profil', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Langue de sortie',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Utilisee pour traduire les etiquettes, les plats photographies et les '
              'produits scannes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            languageAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e'),
              data: (language) => DropdownButtonFormField<String>(
                initialValue: language,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final code in supportedLanguages.keys)
                    DropdownMenuItem(
                      value: code,
                      child: Text(languageDisplayName(code)),
                    ),
                ],
                onChanged: (code) {
                  if (code == null) return;

                  ref
                      .read(languageControllerProvider.notifier)
                      .setLanguage(code);
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mes allergies',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      hintText: 'Ex. arachide, gluten, lait…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: const Text('Ajouter')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: allergiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (allergies) {
                  if (allergies.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucune allergie enregistrée.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final allergy in allergies)
                        Chip(
                          label: Text(allergy),
                          onDeleted: () => ref
                              .read(allergyControllerProvider.notifier)
                              .remove(allergy),
                        ),
                    ],
                  );
                },
              ),
            ),
            Text(
              'Score indicatif, ne remplace pas un avis nutritionniste.',
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
