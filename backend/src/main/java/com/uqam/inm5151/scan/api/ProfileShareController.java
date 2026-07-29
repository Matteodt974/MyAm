package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.ProfileShareRequest;
import com.uqam.inm5151.scan.dto.ProfileShareResponse;
import com.uqam.inm5151.scan.dto.SharedProfileResponse;
import com.uqam.inm5151.scan.service.ProfileShareService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * UC-28 : generation et consommation des codes QR de partage de profil enfant.
 *
 * <p>Toutes les routes exigent un compte authentifie : le beneficiaire du code doit donc posseder
 * un compte MyAm pour importer le profil.
 */
@RestController
@RequestMapping("/v1")
@Validated
public class ProfileShareController {

  private final ProfileShareService shares;

  public ProfileShareController(ProfileShareService shares) {
    this.shares = shares;
  }

  @PostMapping("/children/{childId}/shares")
  @ResponseStatus(HttpStatus.CREATED)
  public ProfileShareResponse create(
      @PathVariable Long childId, @RequestBody @Valid ProfileShareRequest request) {
    return shares.create(childId, request);
  }

  @GetMapping("/profile-shares/{token}")
  public SharedProfileResponse redeem(@PathVariable String token) {
    return shares.redeem(token);
  }

  @DeleteMapping("/children/{childId}/shares/{shareId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void revoke(@PathVariable Long childId, @PathVariable Long shareId) {
    shares.revoke(childId, shareId);
  }
}
