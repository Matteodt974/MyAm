import 'dart:convert';

import 'package:flutter/material.dart';

import '../../scan_barcode/data/product_result.dart';
import '../../scan_barcode/presentation/product_result_sheet.dart';
import '../../scan_dish/data/dish_result.dart';
import '../../scan_dish/presentation/dish_result_sheet.dart';
import '../../scan_label/data/label_result.dart';
import '../../scan_label/presentation/label_result_sheet.dart';
import '../data/scan_history_entry.dart';

/// Bottom sheet that re-opens the original result sheet for a history entry.
class HistoryDetailSheet extends StatelessWidget {
  const HistoryDetailSheet({super.key, required this.entry});

  final ScanHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    try {
      final json = jsonDecode(entry.rawJson) as Map<String, dynamic>;

      switch (entry.type) {
        case ScanType.barcode:
          final result = ProductResult.fromJson(json);
          return ProductResultSheet(product: result);
        case ScanType.dish:
          final result = DishResult.fromJson(json);
          return DishResultSheet(result: result);
        case ScanType.label:
          final result = LabelResult.fromJson(json);
          return LabelResultSheet(result: result);
      }
    } catch (_) {
      return const Center(child: Text("Impossible d'afficher le détail"));
    }
  }
}
