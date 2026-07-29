package com.uqam.inm5151.scan.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * UC-26 : rapport d'analyse d'intolerance potentielle.
 *
 * <p>Les statuts alternatifs ({@code INSUFFICIENT_FOOD_DATA}, {@code NO_JOURNAL_ENTRIES}) sont des
 * resultats metier renvoyes en 200, pas des erreurs HTTP : le frontend affiche alors {@code
 * message} et masque les sections d'analyse.
 */
public record IntoleranceAnalysisResponse(
    String status,
    String message,
    BristolSummary bristolSummary,
    List<String> probableDeficiencies,
    List<IrritantSuggestion> possibleIrritants,
    String medicalDisclaimer) {

  public static final String STATUS_OK = "OK";
  public static final String STATUS_INSUFFICIENT_FOOD_DATA = "INSUFFICIENT_FOOD_DATA";
  public static final String STATUS_NO_JOURNAL_ENTRIES = "NO_JOURNAL_ENTRIES";

  /** Repartition des episodes du journal digestif par type Bristol. */
  public record BristolSummary(
      int entryCount,
      Map<Integer, Integer> typeCounts,
      String dominantProfile,
      int constipationEpisodes,
      int diarrheaEpisodes,
      int normalEpisodes) {}

  /** Aliment consomme dans la fenetre precedant au moins un episode de diarrhee (types 6-7). */
  public record IrritantSuggestion(
      String foodName, List<String> allergens, int episodesPreceded, Instant lastConsumedAt) {}
}
