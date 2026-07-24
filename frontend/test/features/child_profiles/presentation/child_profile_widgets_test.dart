import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/child_profiles/data/child_profile.dart';
import 'package:myam/features/child_profiles/presentation/child_profile_controller.dart';
import 'package:myam/features/child_profiles/presentation/child_profile_management_section.dart';
import 'package:myam/features/child_profiles/presentation/child_profile_selector.dart';

class FakeChildProfileController extends ChildProfileController {
  FakeChildProfileController(this.initialState);

  final ChildProfileState initialState;
  final selectedProfileIds = <int>[];
  final createdNames = <String>[];
  final renamedProfiles = <(int, String)>[];
  final deletedProfileIds = <int>[];

  @override
  Future<ChildProfileState> build() async => initialState;

  @override
  Future<void> select(int profileId) async {
    selectedProfileIds.add(profileId);
    state = AsyncData(state.value!.copyWith(activeProfileId: profileId));
  }

  @override
  Future<void> createChild(String displayName) async {
    createdNames.add(displayName);
  }

  @override
  Future<void> renameChild(int childId, String displayName) async {
    renamedProfiles.add((childId, displayName));
  }

  @override
  Future<void> deleteChild(int childId) async {
    deletedProfileIds.add(childId);
  }
}

void main() {
  const parent = ChildProfile(id: 7, displayName: 'Moi', isChild: false);
  const child = ChildProfile(id: 12, displayName: 'Léa', isChild: true);
  const initialState = ChildProfileState(
    profiles: [parent, child],
    activeProfileId: 7,
  );

  Future<FakeChildProfileController> pumpWidget(
    WidgetTester tester,
    Widget childWidget,
  ) async {
    final controller = FakeChildProfileController(initialState);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childProfileControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp(home: Scaffold(body: childWidget)),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('selector displays profiles and changes the active profile', (
    tester,
  ) async {
    final controller = await pumpWidget(tester, const ChildProfileSelector());

    expect(find.text('Moi'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Léa').last);
    await tester.pumpAndSettle();

    expect(controller.selectedProfileIds, [child.id]);
    expect(find.text('Léa'), findsOneWidget);
  });

  testWidgets('management section creates a child from the dialog value', (
    tester,
  ) async {
    final controller = await pumpWidget(
      tester,
      const ChildProfileManagementSection(),
    );

    await tester.tap(find.text('Ajouter un enfant'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Noah');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(controller.createdNames, ['Noah']);
  });

  testWidgets('management section renames an existing child', (tester) async {
    final controller = await pumpWidget(
      tester,
      const ChildProfileManagementSection(),
    );

    await tester.tap(find.byTooltip('Modifier le nom'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.initialValue, child.displayName);

    await tester.enterText(find.byType(TextFormField), 'Léa-Rose');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(controller.renamedProfiles, [(child.id, 'Léa-Rose')]);
  });

  testWidgets('management section confirms before deleting a child', (
    tester,
  ) async {
    final controller = await pumpWidget(
      tester,
      const ChildProfileManagementSection(),
    );

    await tester.tap(find.byTooltip('Supprimer le profil'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer le profil?'), findsOneWidget);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(controller.deletedProfileIds, [child.id]);
  });
}
