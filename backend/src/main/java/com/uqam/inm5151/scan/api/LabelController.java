package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.LabelAnalysisResponse;
import com.uqam.inm5151.scan.dto.LabelTextRequest;
import com.uqam.inm5151.scan.service.GeminiDishAnalysisException;
import com.uqam.inm5151.scan.service.LabelAnalysisService;
import com.uqam.inm5151.scan.service.UnsupportedLanguageException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * UC6 - translate_and_structure_label : traduction et structuration d'une liste d'ingredients.
 *
 * <p>Le texte brut est extrait cote mobile (Google ML Kit, UC-04). Le backend detecte la langue via
 * Gemini, traduit vers la langue cible choisie par l'utilisateur si necessaire, puis decoupe la
 * liste d'ingredients.
 */
@RestController
@RequestMapping("/v1/label")
public class LabelController {

  private final LabelAnalysisService labelAnalysis;

  public LabelController(LabelAnalysisService labelAnalysis) {
    this.labelAnalysis = labelAnalysis;
  }

  @PostMapping("/translate-and-structure")
  public LabelAnalysisResponse analyzeLabel(@RequestBody @Valid LabelTextRequest request) {
    try {
      return labelAnalysis.analyze(request.text(), request.language());
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
    } catch (UnsupportedLanguageException | GeminiDishAnalysisException e) {
      throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage());
    }
  }
}
