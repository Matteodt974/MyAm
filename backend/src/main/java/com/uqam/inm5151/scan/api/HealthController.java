package com.uqam.inm5151.scan.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Health check. Utilise par Render et docker-compose pour verifier que l'API est vivante.
 * Equivalent de backend/app/api/routes_health.py.
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }
}
