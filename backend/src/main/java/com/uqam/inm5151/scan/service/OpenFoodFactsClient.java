package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.config.AppProperties;
import com.uqam.inm5151.scan.dto.BarcodeResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

/**
 * Client Open Food Facts. Portage fidele de la logique de backend/app/api/routes_scan.py.
 *
 * <p>Comportement (identique a FastAPI) :
 *
 * <ul>
 *   <li>erreur reseau / timeout -> 502 "Open Food Facts injoignable"
 *   <li>reponse HTTP != 200 -> 502 "Reponse OFF invalide"
 *   <li>corps avec status != 1 -> 404 "Produit introuvable"
 * </ul>
 */
@Service
public class OpenFoodFactsClient {

  private static final String FIELDS =
      "product_name,brands,nutriscore_grade,nova_group,additives_tags,allergens_tags,traces_tags,ingredients_analysis_tags,label_tags";

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

  @SuppressWarnings({"unchecked", "rawtypes"})
  public BarcodeResponse fetchBarcode(
      String ean, List<String> userAllergies, String language, List<Diet> userDiets) {
    String lc = language == null || language.isBlank() ? "en" : language;
    ResponseEntity<Map> resp;
    try {
      resp =
          client
              .get()
              .uri(
                  uri ->
                      uri.path("/api/v2/product/{ean}.json")
                          .queryParam("fields", FIELDS)
                          .queryParam("lc", lc)
                          .build(ean))
              .header("User-Agent", userAgent)
              .retrieve()
              .toEntity(Map.class);
    } catch (ResourceAccessException e) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Open Food Facts injoignable");
    } catch (RestClientResponseException e) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Réponse OFF invalide");
    }

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
    List<String> labelTags = toStringList(p.get("label_tags"));

    List<String> productTags = new ArrayList<>();
    productTags.addAll(labelTags);
    productTags.addAll(ingredientsAnalysisTags);
    productTags.addAll(allergensTags);

    boolean dietCompatible = dietMatch.isUserDietsCompatible(userDiets, productTags, List.of());

    List<String> matched = crossMatch.findMatches(allergensTags, userAllergies);
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
        undetermined);
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
}
