package com.uqam.inm5151.scan;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * Smoke test : verifie que le contexte Spring demarre (tous les beans se cablent).
 * Equivalent du "smoke test (import de l'app)" du job CI FastAPI.
 */
@SpringBootTest
class ScanApplicationTests {

    @Test
    void contextLoads() {
    }
}
