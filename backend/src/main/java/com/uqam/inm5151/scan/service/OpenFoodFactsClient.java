package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.config.AppProperties;
import com.uqam.inm5151.scan.dto.BarcodeResponse;
import com.uqam.inm5151.scan.dto.Nutriments;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

/**
 * Client Open Food Facts. Portage fidele de la logique de
 * backend/app/api/routes_scan.py.
 *
 * <p>
 * Comportement (identique a FastAPI) :
 *
 * <ul>
 * <li>erreur reseau / timeout -> 502 "Open Food Facts injoignable"
 * <li>reponse HTTP != 200 -> 502 "Reponse OFF invalide"
 * <li>corps avec status != 1 -> 404 "Produit introuvable"
 * </ul>
 *
 * <p>
 * Les erreurs transitoires (timeout reseau, 429, 502, 503, 504) sont reessayees
 * jusqu'a {@link
 * #MAX_ATTEMPTS} fois avec un backoff exponentiel avant de remonter le 502. Les
 * autres reponses
 * d'erreur (400, 404, ...) sont definitives et remontent immediatement.
 */
@Service
public class OpenFoodFactsClient {

  private static final Logger log = LoggerFactory.getLogger(OpenFoodFactsClient.class);

  private static final String FIELDS = "product_name,brands,nutriscore_grade,nova_group,additives_tags,allergens_tags,traces_tags,ingredients_analysis_tags,ingredients_text,label_tags,nutriments";

  /** Tentative initiale + 2 reessais. */
  private static final int MAX_ATTEMPTS = 3;

  private static final Duration INITIAL_BACKOFF = Duration.ofMillis(300);

  /** Codes ou OFF nous demande (ou nous laisse esperer) de revenir plus tard. */
  private static final Set<Integer> RETRYABLE_STATUS = Set.of(429, 502, 503, 504);

  private final RestClient client;
  private final String userAgent;
  private final AllergenCrossMatchService crossMatch;
  private final DietMatchService dietMatch;

  public OpenFoodFactsClient(
      AppProperties props, AllergenCrossMatchService crossMatch, DietMatchService dietMatch) {
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(Duration.ofSeconds(10));
    factory.setReadTimeout(Duration.ofSeconds(10));
    this.client = RestClient.builder().baseUrl(props.offBaseUrl()).requestFactory(factory).build();
    this.userAgent = props.offUserAgent();
    this.crossMatch = crossMatch;
    this.dietMatch = dietMatch;
  }

  @SuppressWarnings({ "unchecked", "rawtypes" })
  public BarcodeResponse fetchBarcode(
      String ean, List<String> userAllergies, String language, List<Diet> userDiets) {
    String lc = language == null || language.isBlank() ? "en" : language;
    ResponseEntity<Map> resp = getProduct(ean, lc);

    if (resp.getStatusCode().value() != 200) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Réponse OFF invalide");
    }

    Map<String, Object> data = resp.getBody();
    if (data == null || !Integer.valueOf(1).equals(toInt(data.get("status")))) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Produit introuvable");
    }

    Map<String, Object> p = (Map<String, Object>) data.getOrDefault("product", Map.of());
    List<String> allergensTags = toStringList(p.get("allergens_tags"));
    List<String> tracesTags = toStringList(p.get("traces_tags"));
    List<String> ingredientsAnalysisTags = toStringList(p.get("ingredients_analysis_tags"));
    List<String> ingredientNames = toIngredientNames(p.get("ingredients_text"));
    List<String> labelTags = toStringList(p.get("label_tags"));

    List<String> productTags = new ArrayList<>();
    productTags.addAll(labelTags);
    productTags.addAll(ingredientsAnalysisTags);
    productTags.addAll(allergensTags);

    boolean dietCompatible = dietMatch.isUserDietsCompatible(userDiets, productTags, ingredientNames);

    List<String> matched = crossMatch.findMatches(allergensTags, userAllergies);
    matched = mergeUnique(matched, crossMatch.findMatchesInIngredients(ingredientNames, userAllergies));
    List<String> traces = crossMatch.findTraces(tracesTags, userAllergies);
    List<String> undetermined = crossMatch.findUndetermined(allergensTags, userAllergies);
    String risk = crossMatch.riskLevel(matched, traces, undetermined);
    // TODO : calculer ici le score /100 (formule 60/30/10 du OpsCon)

    return new BarcodeResponse(
        ean,
        (String) p.get("product_name"),
        (String) p.get("brands"),
        (String) p.get("nutriscore_grade"),
        toInt(p.get("nova_group")),
        toStringList(p.get("additives_tags")),
        allergensTags,
        tracesTags,
        ingredientsAnalysisTags,
        labelTags,
        dietCompatible,
        risk,
        matched,
        undetermined,
        toNutriments(p.get("nutriments")));
  }

  /**
   * Appelle OFF en reessayant les erreurs transitoires. Le dernier echec est
   * traduit en 502 avec le
   * meme message que lorsqu'aucun reessai n'etait fait.
   */
  @SuppressWarnings("rawtypes")
  private ResponseEntity<Map> getProduct(String ean, String lc) {
    Duration backoff = INITIAL_BACKOFF;

    for (int attempt = 1;; attempt++) {
      try {
        return client
            .get()
            .uri(
                uri -> uri.path("/api/v2/product/{ean}.json")
                    .queryParam("fields", FIELDS)
                    .queryParam("lc", lc)
                    .build(ean))
            .header("User-Agent", userAgent)
            .retrieve()
            .toEntity(Map.class);
      } catch (ResourceAccessException | RestClientResponseException e) {
        if (attempt >= MAX_ATTEMPTS || !isTransient(e)) {
          throw asBadGateway(e);
        }
        log.warn(
            "Appel OFF en echec (tentative {}/{}), nouvel essai dans {} ms : {}",
            attempt,
            MAX_ATTEMPTS,
            backoff.toMillis(),
            e.getMessage());
        sleep(backoff);
        backoff = backoff.multipliedBy(2);
      }
    }
  }

  /** Timeout / coupure reseau, ou code HTTP que OFF renvoie sous charge. */
  private static boolean isTransient(RuntimeException e) {
    if (e instanceof RestClientResponseException http) {
      return RETRYABLE_STATUS.contains(http.getStatusCode().value());
    }
    return true;
  }

  private static ResponseStatusException asBadGateway(RuntimeException e) {
    String reason = e instanceof RestClientResponseException
        ? "Réponse OFF invalide"
        : "Open Food Facts injoignable";
    return new ResponseStatusException(HttpStatus.BAD_GATEWAY, reason);
  }

  private static void sleep(Duration backoff) {
    try {
      Thread.sleep(backoff.toMillis());
    } catch (InterruptedException interrupted) {
      Thread.currentThread().interrupt();
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Open Food Facts injoignable");
    }
  }

  /**
   * Extrait les valeurs pour 100 g de l'objet {@code nutriments} d'Open Food
   * Facts. Les cles {@code
   * *_100g} sont celles normalisees par OFF, toutes les fiches ne les renseignent
   * pas.
   */
  private static Nutriments toNutriments(Object raw) {
    if (!(raw instanceof Map<?, ?> map)) {
      return new Nutriments(null, null, null, null, null, null);
    }
    return new Nutriments(
        toDouble(map.get("energy-kcal_100g")),
        toDouble(map.get("fat_100g")),
        toDouble(map.get("carbohydrates_100g")),
        toDouble(map.get("proteins_100g")),
        toDouble(map.get("salt_100g")),
        toDouble(map.get("fiber_100g")));
  }

  private static Double toDouble(Object o) {
    if (o instanceof Number n) {
      return n.doubleValue();
    }
    if (o instanceof String s && !s.isBlank()) {
      try {
        return Double.valueOf(s.trim());
      } catch (NumberFormatException ignored) {
        return null;
      }
    }
    return null;
  }

  private static Integer toInt(Object o) {
    if (o instanceof Number n) {
      return n.intValue();
    }
    if (o instanceof String s && !s.isBlank()) {
      try {
        return Integer.valueOf(s.trim());
      } catch (NumberFormatException ignored) {
        return null;
      }
    }
    return null;
  }

  private static List<String> toStringList(Object o) {
    if (o instanceof List<?> list) {
      return list.stream().map(String::valueOf).toList();
    }
    return List.of();
  }

  private static List<String> toIngredientNames(Object o) {
    if (o instanceof String s && !s.isBlank()) {
      return List.of(s);
    }
    if (o instanceof List<?> list) {
      return list.stream().map(String::valueOf).toList();
    }
    return List.of();
  }

  private static List<String> mergeUnique(List<String> first, List<String> second) {
    List<String> merged = new ArrayList<>(first);
    for (String value : second) {
      if (!merged.contains(value)) {
        merged.add(value);
      }
    }
    return merged;
  }
}
