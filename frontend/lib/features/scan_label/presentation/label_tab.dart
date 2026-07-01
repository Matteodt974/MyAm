import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../data/label_result.dart';
import 'label_controller.dart';
import 'label_result_sheet.dart';

class LabelTab extends ConsumerStatefulWidget {
  const LabelTab({super.key});

  @override
  ConsumerState<LabelTab> createState() => _LabelTabState();
}

class _LabelTabState extends ConsumerState<LabelTab> {
  final _picker = ImagePicker();

  // Par defaut ML Kit Text Recognition utilise le script latin.
  // Pour supporter chinois/japonais/coréen/etc., il faudra ajouter les
  // language packs natifs correspondants (Android/iOS).
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile? shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (shot == null) return;

      final inputImage = InputImage.fromFilePath(shot.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();

      if (text.isEmpty) {
        if (!mounted) return;
        _showSnack('Aucun texte détecté sur cette étiquette.');
        return;
      }

      await ref.read(labelControllerProvider.notifier).analyze(text);
    } on Exception catch (e) {
      if (!mounted) return;
      _showSnack('Erreur lors de la lecture de l\'étiquette : $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(labelControllerProvider);

    ref.listen<AsyncValue<LabelResult?>>(labelControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;

          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: false,
            builder: (_) => LabelResultSheet(result: result),
          ).whenComplete(
            () => ref.read(labelControllerProvider.notifier).reset(),
          );
        },
        error: (e, _) {
          _showSnack(_errorMessage(e));
          ref.read(labelControllerProvider.notifier).reset();
        },
      );
    });

    final isLoading = state.isLoading || _isProcessing;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Photographier l\'étiquette', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Prenez une photo de la liste d\'ingrédients pour la traduire et l\'analyser.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre une photo'),
                  ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException && error.statusCode == 422) {
      return error.message.isNotEmpty
          ? error.message
          : 'Analyse impossible (langue non supportée ou erreur de traitement). Veuillez réessayer.';
    }

    return error.toString();
  }
}
