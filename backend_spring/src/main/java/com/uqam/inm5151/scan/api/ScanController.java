package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.BarcodeRequest;
import com.uqam.inm5151.scan.dto.BarcodeResponse;
import com.uqam.inm5151.scan.service.OpenFoodFactsClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * UC2 - scan_food_barcode.
 *
 * <p>Endpoint REEL et fonctionnel : il interroge Open Food Facts et renvoie les champs utiles.
 * Premier "vrai" use case de bout en bout (Flutter -> API -> service externe), sans BD ni OCR.
 * Portage de backend/app/api/routes_scan.py.</p>
 */
@RestController
@RequestMapping("/v1/scan")
public class ScanController {

    private final OpenFoodFactsClient openFoodFacts;

    public ScanController(OpenFoodFactsClient openFoodFacts) {
        this.openFoodFacts = openFoodFacts;
    }

    @PostMapping("/barcode")
    public BarcodeResponse scanBarcode(@RequestBody BarcodeRequest req) {
        return openFoodFacts.fetchBarcode(req.ean());
    }
}
