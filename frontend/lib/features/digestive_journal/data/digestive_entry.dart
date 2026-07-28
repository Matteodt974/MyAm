import 'package:freezed_annotation/freezed_annotation.dart';

part 'digestive_entry.freezed.dart';
part 'digestive_entry.g.dart';

/// Entree du journal digestif (UC-23), sur l'echelle de Bristol.
///
/// Cote serveur le type et les notes sont chiffres au repos : cette classe
/// represente la version dechiffree renvoyee au proprietaire authentifie.
@freezed
abstract class DigestiveEntry with _$DigestiveEntry {
  const factory DigestiveEntry({
    int? id,
    required int bristolType,
    required DateTime occurredAt,
    String? notes,
    DateTime? createdAt,
  }) = _DigestiveEntry;

  factory DigestiveEntry.fromJson(Map<String, dynamic> json) =>
      _$DigestiveEntryFromJson(json);
}
