package com.uqam.inm5151.scan.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * CORS large en dev pour que l'app Flutter (autre origine) puisse appeler l'API.
 * A RESTREINDRE avant la prod : remplace les patterns "*" par tes domaines reels.
 *
 * <p>Equivalent du CORSMiddleware de backend/app/main.py. Note : avec
 * {@code allowCredentials(true)}, Spring interdit {@code allowedOrigins("*")} ; on utilise
 * donc {@code allowedOriginPatterns("*")}.</p>
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("*")
                .allowedHeaders("*")
                .allowCredentials(true);
    }
}
