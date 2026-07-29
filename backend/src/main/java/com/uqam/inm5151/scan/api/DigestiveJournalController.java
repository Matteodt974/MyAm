package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.DigestiveEntryRequest;
import com.uqam.inm5151.scan.dto.DigestiveEntryResponse;
import com.uqam.inm5151.scan.service.DigestiveJournalService;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * UC-23 - journal digestif (echelle de Bristol).
 *
 * <p>Endpoints authentifies : le userId est resolu depuis le principal JWT (email). Les entrees
 * sont chiffrees au repos cote serveur.
 */
@RestController
@RequestMapping("/v1/digestive-journal")
@Validated
public class DigestiveJournalController {

  private final DigestiveJournalService journal;

  public DigestiveJournalController(DigestiveJournalService journal) {
    this.journal = journal;
  }

  @PostMapping
  public ResponseEntity<DigestiveEntryResponse> create(
      Authentication authentication, @RequestBody @Valid DigestiveEntryRequest request) {
    DigestiveEntryResponse created =
        journal.create(authentication.getName(), request.profileId(), request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
  }

  @GetMapping
  public List<DigestiveEntryResponse> list(
      Authentication authentication,
      @RequestParam Long profileId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
          Instant since) {
    return journal.list(authentication.getName(), profileId, since);
  }
}
