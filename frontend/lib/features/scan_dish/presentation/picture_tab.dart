import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../profile_allergies/presentation/allergy_controller.dart';
import '../../scan_label/data/label_result.dart';
import '../../scan_label/presentation/label_controller.dart';
import '../../scan_label/presentation/label_result_sheet.dart';
import '../data/dish_result.dart';
import 'dish_controller.dart';
import 'dish_result_sheet.dart';

class PictureTab extends ConsumerStatefulWidget {
  const PictureTab({super.key});

  @override
  ConsumerState<PictureTab> createState() => _PictureTabState();
}

class _PictureTabState extends ConsumerState<PictureTab> {
  final _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (shot == null) return;

    await ref.read(dishControllerProvider.notifier).analyze(File(shot.path));
  }

  Future<void> _scanLabel() async {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (shot == null) return;

    final inputImage = InputImage.fromFilePath(shot.path);
    final recognizer = TextRecognizer();
    final result = await recognizer.processImage(inputImage);
    await recognizer.close();

    final rawText = result.text;
    if (rawText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun texte détecté sur l\'image.')),
        );
      }
      return;
    }

    final allergies = ref.read(allergyControllerProvider).value ?? [];
    await ref.read(labelControllerProvider.notifier).analyze(rawText, allergies);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dishState = ref.watch(dishControllerProvider);
    final labelState = ref.watch(labelControllerProvider);
    final isLoading = dishState.isLoading || labelState.isLoading;

    ref.listen<AsyncValue<DishResult?>>(dishControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;

          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: false,
            builder: (_) => DishResultSheet(result: result),
          ).whenComplete(
            () => ref.read(dishControllerProvider.notifier).reset(),
          );
        },
        error: (e, _) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
          ref.read(dishControllerProvider.notifier).reset();
        },
      );
    });

    ref.listen<AsyncValue<LabelResult?>>(labelControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;

          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => LabelResultSheet(result: result),
          ).whenComplete(
            () => ref.read(labelControllerProvider.notifier).reset(),
          );
        },
        error: (e, _) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
          ref.read(labelControllerProvider.notifier).reset();
        },
      );
    });

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
              Icons.photo_camera_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Photo', style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            if (isLoading)
              const CircularProgressIndicator()
            else ...[
              FilledButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Photo d\'un plat'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _scanLabel,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Scanner une étiquette'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
