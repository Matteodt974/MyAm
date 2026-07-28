import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'consent_controller.dart';

/// Shows the privacy consent dialog for the digestive journal feature.
///
/// Returns:
/// - `true`: user accepted
/// - `false`: user refused via button
/// - `null`: user pressed the system back button (Android only)
///
/// The dialog cannot be dismissed by tapping outside
/// ([barrierDismissible] is false).
Future<bool?> showConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ConsentScreen(),
  );
}

class _ConsentScreen extends ConsumerStatefulWidget {
  const _ConsentScreen();

  @override
  ConsumerState<_ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<_ConsentScreen> {
  bool _rememberChoice = false;

  void _accept() {
    unawaited(
      ref
          .read(consentControllerProvider.notifier)
          .giveConsent(rememberChoice: _rememberChoice),
    );
    Navigator.of(context).pop(true);
  }

  void _refuse() {
    ref.read(consentControllerProvider.notifier).refuseConsent();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Avertissement de confidentialité',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Les données du journal digestif sont des données médicales '
              'sensibles. Elles sont chiffrées de bout en bout et stockées '
              'localement sur votre appareil. Vous gardez le contrôle total '
              'sur ces informations et sur leur éventuel partage avec un '
              'médecin.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _rememberChoice,
              onChanged: (v) => setState(() => _rememberChoice = v ?? false),
              title: const Text('Mémoriser mon choix'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _accept,
              child: const Text('Accepter et continuer'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _refuse, child: const Text('Refuser')),
          ],
        ),
      ),
    );
  }
}
