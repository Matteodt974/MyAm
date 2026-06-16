package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.config.AppProperties;
import com.uqam.inm5151.scan.dto.DishResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Service
public class FoodDataCentralClient {

  private final RestClient client;
  private final String apiKey;

  public FoodDataCentralClient(AppProperties props) {
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(Duration.ofSeconds(10));
    factory.setReadTimeout(Duration.ofSeconds(10));
    this.client = RestClient.builder().baseUrl(props.fdcBaseUrl()).requestFactory(factory).build();
    this.apiKey = props.fdcApiKey();
  }

  @SuppressWarnings({"rawtypes", "unchecked"})
  public List<DishResponse.FoodDataMatch> search(String query, int limit) {
    if (query == null || query.isBlank()) {
      return List.of();
    }

    Map response;
    try {
      response =
          client
              .get()
              .uri(
                  uri ->
                      uri.path("/fdc/v1/foods/search")
                          .queryParam("api_key", apiKey)
                          .queryParam("query", query)
                          .queryParam("pageSize", limit)
                          .build())
              .retrieve()
              .body(Map.class);
    } catch (ResourceAccessException | RestClientResponseException e) {
      return List.of();
    }

    Object foods = response == null ? null : response.get("foods");
    if (!(foods instanceof List<?> list)) {
      return List.of();
    }

    Map<Integer, DishResponse.FoodDataMatch> matches = new LinkedHashMap<>();
    for (Object item : list) {
      if (!(item instanceof Map<?, ?> food)) {
        continue;
      }
      Integer fdcId = toInt(food.get("fdcId"));
      if (fdcId == null || matches.containsKey(fdcId)) {
        continue;
      }
      matches.put(
          fdcId,
          new DishResponse.FoodDataMatch(
              fdcId,
              stringOrNull(food.get("description")),
              stringOrNull(food.get("dataType")),
              stringOrNull(food.get("brandOwner")),
              stringOrNull(food.get("ingredients"))));
      if (matches.size() >= limit) {
        break;
      }
    }
    return List.copyOf(matches.values());
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

  private static String stringOrNull(Object o) {
    String value = o == null ? null : String.valueOf(o).trim();
    return value == null || value.isBlank() ? null : value;
  }
}
