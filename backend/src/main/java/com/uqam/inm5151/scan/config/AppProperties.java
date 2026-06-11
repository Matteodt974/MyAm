package com.uqam.inm5151.scan.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration centralisee, lue depuis les variables d'environnement (via application.yml).
 * Equivalent du Settings pydantic-settings de backend/app/core/config.py.
 *
 * <p>Tous les champs ont une valeur par defaut fournie dans application.yml, donc le binding
 * dispose toujours d'une valeur.</p>
 */
@ConfigurationProperties(prefix = "scan")
public record AppProperties(
        String appName,
        String environment,

        // Optionnel tant que la BD n'est pas branchee (chaine vide si non defini).
        String databaseUrl,

        // Services internes (noms de service docker-compose).
        String ocrUrl,
        String translateUrl,

        // APIs externes open data.
        String offBaseUrl,
        String obfBaseUrl,

        // Open Food Facts EXIGE un User-Agent identifiable, sinon l'IP serveur peut etre
        // throttlee/bannie. Mettre un vrai contact d'equipe.
        String offUserAgent
) {
}
