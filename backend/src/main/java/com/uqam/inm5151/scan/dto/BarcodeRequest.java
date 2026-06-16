package com.uqam.inm5151.scan.dto;

import java.util.List;

/**
 * Corps de la requete POST /v1/scan/barcode. Equivalent du BarcodeRequest
 * pydantic.
 */
public record BarcodeRequest(String ean, List<String> allergies) {

}
