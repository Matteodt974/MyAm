package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Reponse de POST /v1/scan/dish (UC5 stretch - scan_dish).
 *
 * <p>Contrat JSON identique au backend FastAPI : cles snake_case ({@code content_type},
 * {@code size_bytes}), champs nuls conserves grace a {@code JsonInclude.Include.ALWAYS}.
 * L'identification reelle du plat n'est pas encore branchee : {@code status} vaut
 * {@code "not_implemented"} et {@code candidates} est vide. Portage de
 * backend/app/api/routes_scan.py::scan_dish.</p>
 */
@JsonInclude(JsonInclude.Include.ALWAYS)
public record DishResponse(
        String filename,
        @JsonProperty("content_type") String contentType,
        @JsonProperty("size_bytes") long sizeBytes,
        String status,
        String message,
        List<String> candidates
) {
}
