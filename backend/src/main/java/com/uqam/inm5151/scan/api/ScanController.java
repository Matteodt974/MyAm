package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.BarcodeRequest;
import com.uqam.inm5151.scan.dto.BarcodeResponse;
import com.uqam.inm5151.scan.dto.DishResponse;
import com.uqam.inm5151.scan.dto.LabelRequest;
import com.uqam.inm5151.scan.dto.LabelResponse;
import com.uqam.inm5151.scan.service.AllergenCrossMatchService;
import com.uqam.inm5151.scan.service.DishAnalysisService;
import com.uqam.inm5151.scan.service.IngredientExtractorService;
import com.uqam.inm5151.scan.service.OpenFoodFactsClient;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

/**
 * UC2 - scan_food_barcode.
 *
 * <p>
 * Endpoint REEL et fonctionnel : il interroge Open Food Facts et renvoie les
 * champs utiles.
 * Premier "vrai" use case de bout en bout (Flutter -> API -> service externe),
 * sans BD ni OCR.
 * Portage de backend/app/api/routes_scan.py.
 */
@RestController
@RequestMapping("/v1/scan")
public class ScanController {

  private final OpenFoodFactsClient openFoodFacts;
  private final DishAnalysisService dishAnalysis;
  private final IngredientExtractorService ingredientExtractor;
  private final AllergenCrossMatchService allergenCrossmatch;

  public ScanController(OpenFoodFactsClient openFoodFacts, DishAnalysisService dishAnalysis,
      IngredientExtractorService ingredientExtractor, AllergenCrossMatchService allergenCrossmatch) {
    this.openFoodFacts = openFoodFacts;
    this.dishAnalysis = dishAnalysis;
    this.ingredientExtractor = ingredientExtractor;
    this.allergenCrossmatch = allergenCrossmatch;

  }

  @PostMapping("/barcode")
  public BarcodeResponse scanBarcode(@RequestBody BarcodeRequest req) {
    return openFoodFacts.fetchBarcode(req.ean(), req.allergies(), req.language());
  }

  /**
   * UC7 - scan_dish : identification d'un plat a partir d'une photo.
   *
   * <p>
   * L'onglet "Picture" de l'app envoie ici une image en multipart (champ
   * {@code image}). Loi 25
   * / RGPD : l'image n'est JAMAIS persistee.
   */
  @PostMapping(value = "/dish", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public DishResponse scanDish(
      @RequestParam("image") MultipartFile image,
      @RequestParam(value = "language", required = false) String language) {
    String contentType = image.getContentType();
    if (contentType == null || !contentType.startsWith("image/")) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le fichier doit être une image");
    }

    return dishAnalysis.analyze(image, language);
  }

  @PostMapping("/label")
  public LabelResponse scanLabel(@RequestBody LabelRequest req) {
    List<String> ingredients = ingredientExtractor.extract(req.rawText());
    List<String> matched = allergenCrossmatch.findMatchesInIngredients(ingredients, req.allergies());
    List<String> undetermined = allergenCrossmatch.findUndetermined(ingredients, req.allergies());
    String riskLevel = allergenCrossmatch.riskLevel(matched, List.of(), undetermined);
    return new LabelResponse(ingredients, riskLevel, matched, undetermined);
  }

}
