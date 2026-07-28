package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.dto.IntoleranceAnalysisRequest.FoodItem;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse.BristolSummary;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse.IrritantSuggestion;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import org.springframework.stereotype.Service;

/**
 * UC-26 : moteur de regles deterministe (sans LLM) qui correle les episodes du journal digestif
 * (echelle de Bristol) avec les aliments consommes.
 *
 * <p>Regles du cahier des charges :
 *
 * <ul>
 *   <li>types 1-2 (constipation) : apport insuffisant probable en fibres et en hydratation ;
 *   <li>types 6-7 (diarrhee) : irritant alimentaire possible parmi les scans recents ;
 *   <li>types 3-4 (normal) : aucune carence. Le type 5, absent du cahier des charges, est range
 *       cote normal (mou mais sans signe pathologique franc).
 * </ul>
 */
@Service
public class IntoleranceRuleEngine {

  /**
   * En dessous de 3 aliments sur 72 h, une correlation n'a aucune valeur : statut {@code
   * INSUFFICIENT_FOOD_DATA} (scenario alternatif du UC).
   */
  public static final int MIN_FOOD_ITEMS_72H = 3;

  /**
   * Fenetre de correlation avant un episode de diarrhee. Le delai typique entre l'ingestion d'un
   * irritant et une reaction digestive est de 4 a 24 h ; 24 h couvre la grande majorite des cas
   * sans rendre suspects tous les aliments des 72 h.
   */
  public static final Duration IRRITANT_WINDOW = Duration.ofHours(24);

  private static final int MAX_IRRITANTS = 5;

  public static final String MEDICAL_DISCLAIMER =
      "Ces suggestions ne remplacent pas un avis médical. Consultez un médecin ou un(e)"
          + " diététiste avant tout changement d'alimentation.";

  private static final String INSUFFICIENT_FOOD_DATA_MESSAGE =
      "Données alimentaires insuffisantes sur les 72 dernières heures : la corrélation ne peut"
          + " pas être calculée. Scannez vos repas régulièrement puis relancez l'analyse.";

  /** Episode du journal digestif deja dechiffre. */
  public record DigestiveEpisode(Instant occurredAt, int bristolType) {}

  private enum Profile {
    CONSTIPATION,
    NORMAL,
    DIARRHEE
  }

  public IntoleranceAnalysisResponse analyze(
      List<DigestiveEpisode> episodes, List<FoodItem> foodItems) {
    if (foodItems.size() < MIN_FOOD_ITEMS_72H) {
      return new IntoleranceAnalysisResponse(
          IntoleranceAnalysisResponse.STATUS_INSUFFICIENT_FOOD_DATA,
          INSUFFICIENT_FOOD_DATA_MESSAGE,
          null,
          List.of(),
          List.of(),
          MEDICAL_DISCLAIMER);
    }

    BristolSummary summary = summarize(episodes);
    List<IrritantSuggestion> irritants =
        summary.diarrheaEpisodes() > 0 ? correlateIrritants(episodes, foodItems) : List.of();
    List<String> deficiencies = deficiencies(summary, irritants);

    return new IntoleranceAnalysisResponse(
        IntoleranceAnalysisResponse.STATUS_OK,
        null,
        summary,
        deficiencies,
        irritants,
        MEDICAL_DISCLAIMER);
  }

  private static Profile classify(int bristolType) {
    if (bristolType <= 2) {
      return Profile.CONSTIPATION;
    }
    return bristolType >= 6 ? Profile.DIARRHEE : Profile.NORMAL;
  }

  private static BristolSummary summarize(List<DigestiveEpisode> episodes) {
    Map<Integer, Integer> typeCounts = new TreeMap<>();
    int constipation = 0;
    int diarrhea = 0;
    int normal = 0;
    for (DigestiveEpisode episode : episodes) {
      typeCounts.merge(episode.bristolType(), 1, Integer::sum);
      switch (classify(episode.bristolType())) {
        case CONSTIPATION -> constipation++;
        case DIARRHEE -> diarrhea++;
        case NORMAL -> normal++;
      }
    }

    return new BristolSummary(
        episodes.size(),
        typeCounts,
        dominantProfile(constipation, diarrhea, normal),
        constipation,
        diarrhea,
        normal);
  }

  /**
   * Profil dominant = la categorie ayant le plus d'episodes ; {@code MIXTE} en cas d'egalite entre
   * plusieurs categories (y compris quand toutes valent 0).
   */
  private static String dominantProfile(int constipation, int diarrhea, int normal) {
    int max = Math.max(constipation, Math.max(diarrhea, normal));
    int tied = 0;
    if (constipation == max) tied++;
    if (diarrhea == max) tied++;
    if (normal == max) tied++;

    if (tied > 1) {
      return "MIXTE";
    } else if (constipation == max) {
      return "CONSTIPATION";
    } else if (diarrhea == max) {
      return "DIARRHEE";
    } else {
      return "NORMAL";
    }
  }

  private static List<String> deficiencies(
      BristolSummary summary, List<IrritantSuggestion> irritants) {
    List<String> result = new ArrayList<>();
    if (summary.constipationEpisodes() > 0) {
      result.add("Apport insuffisant probable en fibres");
      result.add("Hydratation possiblement insuffisante");
    }
    if (summary.diarrheaEpisodes() > 0 && !irritants.isEmpty()) {
      result.add("Irritant alimentaire possible identifié parmi vos scans récents");
    }
    return result;
  }

  /**
   * Pour chaque episode type 6-7, retient les aliments consommes dans les {@link #IRRITANT_WINDOW}
   * qui le precedent, puis agrege par nom (casse-insensible). Tri : nombre d'episodes precedes
   * decroissant, puis presence d'allergenes detectes, puis ordre alphabetique.
   */
  private static List<IrritantSuggestion> correlateIrritants(
      List<DigestiveEpisode> episodes, List<FoodItem> foodItems) {
    Map<String, Aggregate> byName = new LinkedHashMap<>();

    for (DigestiveEpisode episode : episodes) {
      if (classify(episode.bristolType()) != Profile.DIARRHEE) {
        continue;
      }
      Instant windowStart = episode.occurredAt().minus(IRRITANT_WINDOW);
      for (FoodItem item : foodItems) {
        Instant consumedAt = item.consumedAt();
        boolean inWindow =
            !consumedAt.isBefore(windowStart) && !consumedAt.isAfter(episode.occurredAt());
        if (inWindow) {
          byName
              .computeIfAbsent(item.name().toLowerCase(Locale.ROOT), k -> new Aggregate(item))
              .record(episode, item);
        }
      }
    }

    return byName.values().stream()
        .map(Aggregate::toSuggestion)
        .sorted(
            Comparator.comparingInt(IrritantSuggestion::episodesPreceded)
                .reversed()
                .thenComparing(s -> s.allergens().isEmpty())
                .thenComparing(IrritantSuggestion::foodName))
        .limit(MAX_IRRITANTS)
        .toList();
  }

  /** Accumulateur par aliment : episodes distincts precedes et derniere consommation. */
  private static final class Aggregate {
    private final String displayName;
    private final List<String> allergens = new ArrayList<>();
    private final List<Instant> episodesSeen = new ArrayList<>();
    private Instant lastConsumedAt;

    private Aggregate(FoodItem first) {
      this.displayName = first.name();
    }

    private void record(DigestiveEpisode episode, FoodItem item) {
      if (!episodesSeen.contains(episode.occurredAt())) {
        episodesSeen.add(episode.occurredAt());
      }
      for (String allergen : item.allergens()) {
        if (!allergens.contains(allergen)) {
          allergens.add(allergen);
        }
      }
      if (lastConsumedAt == null || item.consumedAt().isAfter(lastConsumedAt)) {
        lastConsumedAt = item.consumedAt();
      }
    }

    private IrritantSuggestion toSuggestion() {
      return new IrritantSuggestion(
          displayName, List.copyOf(allergens), episodesSeen.size(), lastConsumedAt);
    }
  }
}
