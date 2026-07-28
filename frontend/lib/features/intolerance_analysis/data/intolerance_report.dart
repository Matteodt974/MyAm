import 'package:freezed_annotation/freezed_annotation.dart';

part 'intolerance_report.freezed.dart';
part 'intolerance_report.g.dart';

/// Statuts renvoyes par `POST /v1/analysis/intolerance`.
///
/// Les deux statuts autres que [ok] sont des resultats metier (HTTP 200) : le
/// backend explique dans `message` pourquoi l'analyse n'a pas pu etre faite.
abstract final class IntoleranceStatus {
  static const String ok = 'OK';
  static const String insufficientFoodData = 'INSUFFICIENT_FOOD_DATA';
  static const String noJournalEntries = 'NO_JOURNAL_ENTRIES';
}

/// Rapport d'analyse d'intolerance potentielle (UC-26).
@freezed
abstract class IntoleranceReport with _$IntoleranceReport {
  const factory IntoleranceReport({
    @Default(IntoleranceStatus.ok) String status,
    String? message,
    BristolSummary? bristolSummary,
    @Default(<String>[]) List<String> probableDeficiencies,
    @Default(<IrritantSuggestion>[]) List<IrritantSuggestion> possibleIrritants,
    @Default('') String medicalDisclaimer,
  }) = _IntoleranceReport;

  factory IntoleranceReport.fromJson(Map<String, dynamic> json) =>
      _$IntoleranceReportFromJson(json);
}

/// Repartition des episodes du journal digestif par type de Bristol.
@freezed
abstract class BristolSummary with _$BristolSummary {
  const factory BristolSummary({
    @Default(0) int entryCount,
    @Default(<int, int>{}) Map<int, int> typeCounts,
    String? dominantProfile,
    @Default(0) int constipationEpisodes,
    @Default(0) int diarrheaEpisodes,
    @Default(0) int normalEpisodes,
  }) = _BristolSummary;

  factory BristolSummary.fromJson(Map<String, dynamic> json) =>
      _$BristolSummaryFromJson(json);
}

/// Aliment consomme dans la fenetre precedant un episode de diarrhee.
@freezed
abstract class IrritantSuggestion with _$IrritantSuggestion {
  const factory IrritantSuggestion({
    @Default('') String foodName,
    @Default(<String>[]) List<String> allergens,
    @Default(0) int episodesPreceded,
    DateTime? lastConsumedAt,
  }) = _IrritantSuggestion;

  factory IrritantSuggestion.fromJson(Map<String, dynamic> json) =>
      _$IrritantSuggestionFromJson(json);
}

/// Aliment du journal alimentaire des 72 h envoye au backend.
///
/// Construit a partir de l'historique de scans local : le journal alimentaire
/// n'est jamais synchronise en base, il voyage avec la requete d'analyse.
class FoodItemPayload {
  const FoodItemPayload({
    required this.name,
    required this.consumedAt,
    this.allergens = const <String>[],
    this.scanType,
  });

  final String name;
  final DateTime consumedAt;
  final List<String> allergens;
  final String? scanType;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'consumedAt': consumedAt.toUtc().toIso8601String(),
    'allergens': allergens,
    if (scanType != null) 'scanType': scanType,
  };
}
