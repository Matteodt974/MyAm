import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final state = ref.watch(dishControllerProvider);

    ref.listen<AsyncValue<DishResult?>>(dishControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;

          showModalBottomSheet<void>(
            context: context,
            showDragHandle: false,
            builder: (_) => DishResultSheet(result: result),
          ).whenComplete(
            () => ref.read(dishControllerProvider.notifier).reset(),
          );
        },
        error: (e, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));

          ref.read(dishControllerProvider.notifier).reset();
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
              Icons.restaurant_menu,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Photo d\'un plat', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Prenez une photo de votre assiette pour l\'analyser.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            state.isLoading
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
}
