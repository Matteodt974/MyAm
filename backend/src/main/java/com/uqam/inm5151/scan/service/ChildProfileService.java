package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.ChildProfileRequest;
import com.uqam.inm5151.scan.dto.ChildProfileResponse;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ChildProfileService {
  private final UserRepository users;

  public ChildProfileService(UserRepository users) {
    this.users = users;
  }

  @Transactional(readOnly = true)
  public List<ChildProfileResponse> list(Long guardianId) {

    requireStandaloneGuardian(guardianId);

    return users.findAllByGuardianUserIdOrderByDisplayNameAsc(guardianId).stream()
        .map(ChildProfileResponse::from)
        .toList();
  }

  @Transactional
  public ChildProfileResponse create(Long guardianId, ChildProfileRequest request) {

    requireStandaloneGuardian(guardianId);

    User child = new User(request.displayName().trim(), AccountType.MANAGED);

    child.setGuardianUserId(guardianId);

    User savedChild = users.save(child);

    return ChildProfileResponse.from(savedChild);
  }

  @Transactional
  public ChildProfileResponse update(Long guardianId, Long childId, ChildProfileRequest request) {

    requireStandaloneGuardian(guardianId);

    User child = requireOwnedChild(guardianId, childId);
    child.setDisplayName(request.displayName().trim());

    User savedChild = users.save(child);

    return ChildProfileResponse.from(savedChild);
  }

  @Transactional
  public void delete(Long guardianId, Long childId) {
    requireStandaloneGuardian(guardianId);
    User child = requireOwnedChild(guardianId, childId);
    users.delete(child);
  }

  private User requireStandaloneGuardian(Long guardianId) {
    User guardian =
        users
            .findById(guardianId)
            .orElseThrow(
                () ->
                    new ResponseStatusException(HttpStatus.NOT_FOUND, "Compte parent introuvable"));

    if (guardian.getAccountType() != AccountType.STANDALONE) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST, "Un sous-profil ne peut pas gérer des enfants");
    }

    return guardian;
  }

  private User requireOwnedChild(Long guardianId, Long childId) {
    User child =
        users
            .findById(childId)
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sous-profil introuvable"));

    boolean isManaged = child.getAccountType() == AccountType.MANAGED;

    boolean belongsToGuardian = guardianId.equals(child.getGuardianUserId());

    if (!isManaged || !belongsToGuardian) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Sous-profil introuvable");
    }

    return child;
  }
}
