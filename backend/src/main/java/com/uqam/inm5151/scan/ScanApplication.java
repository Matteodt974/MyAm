package com.uqam.inm5151.scan;

import com.uqam.inm5151.scan.config.AppProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

/**
 * Point d'entree de l'API Spring Boot. Equivalent de backend/app/main.py (FastAPI).
 */
@SpringBootApplication
@EnableConfigurationProperties(AppProperties.class)
public class ScanApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScanApplication.class, args);
    }
}
