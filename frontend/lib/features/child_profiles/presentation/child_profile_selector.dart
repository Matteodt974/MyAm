import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'child_profile_controller.dart';

class ChildProfileSelector extends ConsumerWidget {
  const ChildProfileSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(childProfileControllerProvider);

    return profiles.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) => Center(
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: state.activeProfileId,
                icon: const Icon(Icons.expand_more),
                items: [
                  for (final profile in state.profiles)
                    DropdownMenuItem(
                      value: profile.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.isChild ? Icons.child_care : Icons.person,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(profile.displayName),
                        ],
                      ),
                    ),
                ],
                onChanged: (profileId) {
                  if (profileId == null) return;
                  ref
                      .read(childProfileControllerProvider.notifier)
                      .select(profileId);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
