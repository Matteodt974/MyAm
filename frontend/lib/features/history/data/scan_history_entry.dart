import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../scan_barcode/data/product_result.dart';
import '../../scan_dish/data/dish_result.dart';
import '../../scan_label/data/label_result.dart';

part 'scan_history_entry.freezed.dart';

part 'scan_history_entry.g.dart';

enum ScanType { barcode, dish, label }

@freezed
abstract class ScanHistoryEntry with _$ScanHistoryEntry {
  const factory ScanHistoryEntry({
    int? id,
    required ScanType type,
    required String title,
    required DateTime scannedAt,
    String? riskLevel,
    @Default(<String>[]) List<String> matchedAllergens,
    String? thumbnailPath,
    required String rawJson,
  }) = _ScanHistoryEntry;

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$ScanHistoryEntryFromJson(json);

  factory ScanHistoryEntry.fromProductResult(
    ProductResult result, {
    DateTime? scannedAt,
  }) => ScanHistoryEntry(
    type: ScanType.barcode,
    title: result.name ?? 'Produit ${result.ean}',
    scannedAt: scannedAt ?? DateTime.now(),
    riskLevel: result.riskLevel,
    matchedAllergens: result.matchedAllergens,
    rawJson: jsonEncode(result.toJson()),
  );

  factory ScanHistoryEntry.fromDishResult(
    DishResult result, {
    List<String> allergies = const <String>[],
    String? thumbnailPath,
    DateTime? scannedAt,
  }) {
    final flagged = flaggedDishIngredients(result.ingredients, allergies);
    return ScanHistoryEntry(
      type: ScanType.dish,
      title: result.dishName ?? 'Plat analysé',
      scannedAt: scannedAt ?? DateTime.now(),
      riskLevel: flagged.isNotEmpty ? 'DANGER' : 'SAFE',
      matchedAllergens: flagged.toList(),
      thumbnailPath: thumbnailPath,
      rawJson: jsonEncode(result.toJson()),
    );
  }

  factory ScanHistoryEntry.fromLabelResult(
    LabelResult result, {
    DateTime? scannedAt,
  }) => ScanHistoryEntry(
    type: ScanType.label,
    title: 'Étiquette analysée',
    scannedAt: scannedAt ?? DateTime.now(),
    matchedAllergens: result.matchedAllergens,
    rawJson: jsonEncode(result.toJson()),
  );
}
