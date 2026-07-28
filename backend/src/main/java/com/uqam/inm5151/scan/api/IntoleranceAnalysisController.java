package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.IntoleranceAnalysisRequest;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse;
import com.uqam.inm5151.scan.service.IntoleranceAnalysisService;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * UC-26 - deduire une intolerance potentielle.
 *
 * <p>Endpoint authentifie. Le frontend envoie le journal alimentaire des 72 dernieres heures
 * (historique de scans local) ; les episodes du journal digestif sont charges cote serveur.
 */
@RestController
@RequestMapping("/v1/analysis")
@Validated
public class IntoleranceAnalysisController {

  private final IntoleranceAnalysisService analysis;

  public IntoleranceAnalysisController(IntoleranceAnalysisService analysis) {
    this.analysis = analysis;
  }

  @PostMapping("/intolerance")
  public IntoleranceAnalysisResponse analyze(
      Authentication authentication, @RequestBody @Valid IntoleranceAnalysisRequest request) {
    return analysis.analyze(authentication.getName(), request);
  }
}
