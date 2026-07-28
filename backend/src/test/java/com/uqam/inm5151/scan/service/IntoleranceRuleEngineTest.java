package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.uqam.inm5151.scan.dto.IntoleranceAnalysisRequest.FoodItem;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse.IrritantSuggestion;
import com.uqam.inm5151.scan.service.IntoleranceRuleEngine.DigestiveEpisode;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

class IntoleranceRuleEngineTest {

  private static final Instant NOW = Instant.parse("2026-07-27T12:00:00Z");

  private final IntoleranceRuleEngine engine = new IntoleranceRuleEngine();

  private static FoodItem food(String name, Instant consumedAt, String... allergens) {
    return new FoodItem(name, consumedAt, List.of(allergens), "barcode");
  }

  private static List<FoodItem> threeSafeFoods() {
    return List.of(
        food("Riz blanc", NOW.minusSeconds(3600)),
        food("Pomme", NOW.minusSeconds(7200)),
        food("Carotte", NOW.minusSeconds(10800)));
  }

  @Test
  void analyze_lessThanThreeFoods_returnsInsufficientFoodData() {
    IntoleranceAnalysisResponse response =
        engine.analyze(
            List.of(new DigestiveEpisode(NOW, 4)), List.of(food("Riz", NOW.minusSeconds(60))));

    assertThat(response.status())
        .isEqualTo(IntoleranceAnalysisResponse.STATUS_INSUFFICIENT_FOOD_DATA);
    assertThat(response.message()).contains("72");
    assertThat(response.bristolSummary()).isNull();
    assertThat(response.medicalDisclaimer()).isNotBlank();
  }

  @Test
  void analyze_constipationEpisodes_suggestsFiberAndHydration() {
    IntoleranceAnalysisResponse response =
        engine.analyze(
            List.of(new DigestiveEpisode(NOW, 1), new DigestiveEpisode(NOW.minusSeconds(3600), 2)),
            threeSafeFoods());

    assertThat(response.status()).isEqualTo(IntoleranceAnalysisResponse.STATUS_OK);
    assertThat(response.probableDeficiencies())
        .containsExactly(
            "Apport insuffisant probable en fibres", "Hydratation possiblement insuffisante");
    assertThat(response.bristolSummary().dominantProfile()).isEqualTo("CONSTIPATION");
    assertThat(response.possibleIrritants()).isEmpty();
  }

  @Test
  void analyze_normalEpisodesOnly_reportsNoDeficiency() {
    IntoleranceAnalysisResponse response =
        engine.analyze(
            List.of(new DigestiveEpisode(NOW, 3), new DigestiveEpisode(NOW.minusSeconds(3600), 4)),
            threeSafeFoods());

    assertThat(response.status()).isEqualTo(IntoleranceAnalysisResponse.STATUS_OK);
    assertThat(response.probableDeficiencies()).isEmpty();
    assertThat(response.possibleIrritants()).isEmpty();
    assertThat(response.bristolSummary().dominantProfile()).isEqualTo("NORMAL");
  }

  @Test
  void analyze_diarrheaEpisode_identifiesFoodInsideWindowOnly() {
    Instant episodeAt = NOW.minusSeconds(3600);
    List<FoodItem> foods =
        List.of(
            food("Lait 2%", episodeAt.minusSeconds(2 * 3600), "lait"),
            food("Poutine", episodeAt.minusSeconds(30 * 3600)),
            food("Pomme", episodeAt.minusSeconds(4 * 3600)));

    IntoleranceAnalysisResponse response =
        engine.analyze(List.of(new DigestiveEpisode(episodeAt, 6)), foods);

    assertThat(response.status()).isEqualTo(IntoleranceAnalysisResponse.STATUS_OK);
    assertThat(response.possibleIrritants())
        .extracting(IrritantSuggestion::foodName)
        .containsExactly("Lait 2%", "Pomme")
        .doesNotContain("Poutine");
    assertThat(response.probableDeficiencies())
        .contains("Irritant alimentaire possible identifié parmi vos scans récents");
  }

  @Test
  void analyze_irritantsSortedByEpisodesPrecededThenAllergens() {
    Instant firstEpisode = NOW.minusSeconds(3600);
    Instant secondEpisode = NOW.minusSeconds(20 * 3600);
    List<FoodItem> foods =
        List.of(
            food("Yogourt", firstEpisode.minusSeconds(3600), "lait"),
            food("Yogourt", secondEpisode.minusSeconds(3600), "lait"),
            food("Salade", firstEpisode.minusSeconds(1800)));

    IntoleranceAnalysisResponse response =
        engine.analyze(
            List.of(new DigestiveEpisode(firstEpisode, 7), new DigestiveEpisode(secondEpisode, 6)),
            foods);

    assertThat(response.possibleIrritants())
        .extracting(IrritantSuggestion::foodName)
        .containsExactly("Yogourt", "Salade");
    assertThat(response.possibleIrritants().getFirst().episodesPreceded()).isEqualTo(2);
    assertThat(response.possibleIrritants().getFirst().allergens()).containsExactly("lait");
  }

  @Test
  void analyze_mixedEpisodesWithoutMajority_profileIsMixte() {
    IntoleranceAnalysisResponse response =
        engine.analyze(
            List.of(new DigestiveEpisode(NOW, 1), new DigestiveEpisode(NOW.minusSeconds(3600), 7)),
            threeSafeFoods());

    assertThat(response.bristolSummary().dominantProfile()).isEqualTo("MIXTE");
    assertThat(response.bristolSummary().constipationEpisodes()).isEqualTo(1);
    assertThat(response.bristolSummary().diarrheaEpisodes()).isEqualTo(1);
  }

  @Test
  void analyze_pluralityWithoutAbsoluteMajority_profileIsDominantCategory() {
    IntoleranceAnalysisResponse response =
        engine.analyze(
            List.of(
                new DigestiveEpisode(NOW, 1),
                new DigestiveEpisode(NOW.minusSeconds(1000), 2),
                new DigestiveEpisode(NOW.minusSeconds(2000), 1),
                new DigestiveEpisode(NOW.minusSeconds(3000), 6),
                new DigestiveEpisode(NOW.minusSeconds(4000), 7),
                new DigestiveEpisode(NOW.minusSeconds(5000), 3)),
            threeSafeFoods());

    assertThat(response.bristolSummary().dominantProfile()).isEqualTo("CONSTIPATION");
    assertThat(response.bristolSummary().constipationEpisodes()).isEqualTo(3);
    assertThat(response.bristolSummary().diarrheaEpisodes()).isEqualTo(2);
    assertThat(response.bristolSummary().normalEpisodes()).isEqualTo(1);
  }

  @Test
  void analyze_typeFiveTreatedAsNormal() {
    IntoleranceAnalysisResponse response =
        engine.analyze(List.of(new DigestiveEpisode(NOW, 5)), threeSafeFoods());

    assertThat(response.bristolSummary().normalEpisodes()).isEqualTo(1);
    assertThat(response.probableDeficiencies()).isEmpty();
  }

  @Test
  void analyze_typeCountsAggregatedPerBristolType() {
    IntoleranceAnalysisResponse response =
        engine.analyze(
            List.of(
                new DigestiveEpisode(NOW, 6),
                new DigestiveEpisode(NOW.minusSeconds(60), 6),
                new DigestiveEpisode(NOW.minusSeconds(120), 3)),
            threeSafeFoods());

    assertThat(response.bristolSummary().typeCounts()).containsEntry(6, 2).containsEntry(3, 1);
    assertThat(response.bristolSummary().entryCount()).isEqualTo(3);
  }
}
