import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/languages.dart';
import '../../../core/providers/auth_state_provider.dart';
import 'allergy_controller.dart';
import 'diet_controller.dart';
import 'language_controller.dart';
import 'trusted_item_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _controller = TextEditingController();

  static const _dietOptions = [
    (value: 'VEGAN', label: 'Vegan'),
    (value: 'VEGETARIAN', label: 'Végétarien'),
    (value: 'PESCETARIAN', label: 'Pescétarien'),
    (value: 'HALAL', label: 'Halal'),
    (value: 'KOSHER', label: 'Kasher'),
    (value: 'GLUTEN_FREE', label: 'Sans gluten'),
    (value: 'LACTOSE_FREE', label: 'Sans lactose'),
  ];

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

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  Widget _buildAccountSection(
    AsyncValue<AuthState> authState,
    ThemeData theme,
  ) {
    final user = authState.maybeWhen(
      data: (state) => state is AuthStateAuthenticated ? state.user : null,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compte',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (user != null)
          Text(user.displayName, style: theme.textTheme.titleSmall)
        else
          Text('Connecté', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          user?.email ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _logout, child: const Text('Se déconnecter')),
      ],
    );
  }

  /// Acces au journal digestif (UC-23) et a l'analyse des tendances (UC-26).
  Widget _buildDigestiveHealthSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Santé digestive',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Données de santé : leur enregistrement est soumis à votre '
          'consentement explicite.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.event_note),
                title: const Text('Journal digestif'),
                subtitle: const Text('Noter un épisode (échelle de Bristol)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/digestive-journal'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.insights),
                title: const Text('Analyse des tendances'),
                subtitle: const Text(
                  'Croiser le journal avec vos scans des 72 dernières heures',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/analysis'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allergiesAsync = ref.watch(allergyControllerProvider);
    final dietsAsync = ref.watch(dietControllerProvider);
    final languageAsync = ref.watch(languageControllerProvider);
    final trustedItemsAsync = ref.watch(trustedItemControllerProvider);
    final authState = ref.watch(authStateProvider);

    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text('Profil', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildAccountSection(authState, theme),
            const SizedBox(height: 24),
            _buildDigestiveHealthSection(theme),
            const SizedBox(height: 24),
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
            allergiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (allergies) {
                if (allergies.isEmpty) {
                  return Text(
                    'Aucune allergie enregistrée.',
                    style: theme.textTheme.bodyMedium,
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
            const SizedBox(height: 24),
            Text(
              'Mes régimes',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            dietsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (diets) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _dietOptions)
                      FilterChip(
                        label: Text(option.label),
                        selected: diets.contains(option.value),
                        onSelected: (_) => ref
                            .read(dietControllerProvider.notifier)
                            .toggle(option.value),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Les régimes choisis seront envoyés avec chaque scan code-barres.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mes items de confiance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            trustedItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    'Aucun item de confiance enregistré.',
                    style: theme.textTheme.bodyMedium,
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      InputChip(
                        label: Text(
                          item.name?.isNotEmpty == true ? item.name! : item.ean,
                        ),
                        avatar: const Icon(Icons.verified, size: 18),
                        onDeleted: () => ref
                            .read(trustedItemControllerProvider.notifier)
                            .remove(item.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
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
