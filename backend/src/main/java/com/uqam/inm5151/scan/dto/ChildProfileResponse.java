package com.uqam.inm5151.scan.dto;

import com.uqam.inm5151.scan.domain.User;
import java.util.Set;

public record ChildProfileResponse(
    Long id, String displayName, Set<String> allergies, Set<String> diets) {

  public static ChildProfileResponse from(User user) {
    return new ChildProfileResponse(
        user.getId(),
        user.getDisplayName(),
        Set.copyOf(user.getAllergies()),
        Set.copyOf(user.getDiets()));
  }
}
