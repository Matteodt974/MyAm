package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import com.uqam.inm5151.scan.config.AppProperties;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

/**
 * Verifie le reessai sur erreurs transitoires (ISSUE-29). Un vrai serveur HTTP local est utilise
 * plutot qu'un mock : le reessai vit dans le client HTTP lui-meme, un stub de RestClient ne le
 * couvrirait pas.
 */
class OpenFoodFactsClientTest {

  private static final String PRODUCT_JSON =
      "{\"status\":1,\"product\":{\"product_name\":\"Biscuits\",\"allergens_tags\":[]}}";

  private HttpServer server;
  private AtomicInteger calls;

  @BeforeEach
  void startServer() throws IOException {
    calls = new AtomicInteger();
    server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
  }

  @AfterEach
  void stopServer() {
    server.stop(0);
  }

  @Test
  void retriesTransientStatusThenSucceeds() {
    // 503, 429, puis succes : le troisieme essai doit passer.
    serve(
        exchange -> {
          int call = calls.incrementAndGet();
          if (call == 1) {
            respond(exchange, 503, "");
          } else if (call == 2) {
            respond(exchange, 429, "");
          } else {
            respond(exchange, 200, PRODUCT_JSON);
          }
        });

    var response = client().fetchBarcode("3017620422003", List.of(), "fr", List.of());

    assertThat(response.name()).isEqualTo("Biscuits");
    assertThat(calls).hasValue(3);
  }

  @Test
  void givesUpAfterThreeAttempts() {
    serve(
        exchange -> {
          calls.incrementAndGet();
          respond(exchange, 502, "");
        });

    assertThatThrownBy(() -> client().fetchBarcode("3017620422003", List.of(), "fr", List.of()))
        .isInstanceOf(ResponseStatusException.class)
        .hasMessageContaining("502")
        .hasMessageContaining("Réponse OFF invalide");
    assertThat(calls).hasValue(3);
  }

  @Test
  void doesNotRetryPermanentStatus() {
    serve(
        exchange -> {
          calls.incrementAndGet();
          respond(exchange, 400, "");
        });

    assertThatThrownBy(() -> client().fetchBarcode("3017620422003", List.of(), "fr", List.of()))
        .isInstanceOf(ResponseStatusException.class);
    assertThat(calls).hasValue(1);
  }

  private void serve(UnsafeHandler handler) {
    server.createContext(
        "/",
        exchange -> {
          try {
            handler.handle(exchange);
          } finally {
            exchange.close();
          }
        });
    server.start();
  }

  private static void respond(HttpExchange exchange, int status, String body) throws IOException {
    byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
    exchange.getResponseHeaders().add("Content-Type", "application/json");
    exchange.sendResponseHeaders(status, bytes.length == 0 ? -1 : bytes.length);
    if (bytes.length > 0) {
      try (OutputStream out = exchange.getResponseBody()) {
        out.write(bytes);
      }
    }
  }

  private OpenFoodFactsClient client() {
    var props =
        new AppProperties(
            "test",
            "test",
            null,
            "http://127.0.0.1:" + server.getAddress().getPort(),
            null,
            "test-agent",
            null,
            null,
            null,
            null,
            "test-master-key");
    return new OpenFoodFactsClient(props, new AllergenCrossMatchService(), new DietMatchService());
  }

  @FunctionalInterface
  private interface UnsafeHandler {
    void handle(HttpExchange exchange) throws IOException;
  }
}
