import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'scan_history_entry.dart';

/// Helper class for exporting [ScanHistoryEntry] data to shareable files.
class ScanHistoryExport {
  /// Exports the given [entries] as a UTF-8 CSV file and opens the system
  /// share sheet to share it.
  ///
  /// The [fileName] defaults to `historique_myam_<yyyy-MM-dd_HH-mm>.csv`.
  Future<void> exportCsv(
    List<ScanHistoryEntry> entries, {
    String? fileName,
  }) async {
    final rows = <List<String>>[
      const ['Date', 'Type', 'Nom', 'Résultat', 'Allergènes'],
      ...entries.map(_entryToRow),
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final effectiveFileName = fileName ?? _defaultFileName();
    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(tempDir.path, effectiveFileName);

    final file = File(filePath);
    // Write with a UTF-8 BOM so spreadsheet applications (notably Excel on
    // Windows) correctly interpret French accented characters.
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...csv.codeUnits], flush: true);

    await Share.shareXFiles([XFile(filePath)]);
  }

  List<String> _entryToRow(ScanHistoryEntry entry) {
    final dateFormat = DateFormat.yMd('fr_CA').add_Hm();

    return [
      dateFormat.format(entry.scannedAt),
      _scanTypeLabel(entry.type),
      entry.title,
      entry.riskLevel ?? '',
      entry.matchedAllergens.join('; '),
    ];
  }

  String _scanTypeLabel(ScanType type) {
    return switch (type) {
      ScanType.barcode => 'Code-barres',
      ScanType.dish => 'Plat',
      ScanType.label => 'Étiquette',
    };
  }

  String _defaultFileName() {
    final now = DateTime.now();
    final formatted =
        '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}_'
        '${_twoDigits(now.hour)}-${_twoDigits(now.minute)}';
    return 'historique_myam_$formatted.csv';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
