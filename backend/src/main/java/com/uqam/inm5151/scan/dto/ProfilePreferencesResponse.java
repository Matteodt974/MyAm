package com.uqam.inm5151.scan.dto;

import com.uqam.inm5151.scan.domain.User;
import java.util.Set;

public record ProfilePreferencesResponse(
    Long profileId, String displayName, Set<String> allergies, Set<String> diets) {

  public static ProfilePreferencesResponse from(User user) {
    return new ProfilePreferencesResponse(
        user.getId(),
        user.getDisplayName(),
        Set.copyOf(user.getAllergies()),
        Set.copyOf(user.getDiets()));
  }
}
