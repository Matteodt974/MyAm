package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.ChildProfileRequest;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class ChildProfileServiceTest {
  @Mock private UserRepository users;

  @Mock private CurrentUserService currentUser;

  @InjectMocks private ChildProfileService service;

  private User standaloneGuardian() {
    User guardian = mock(User.class);
    when(guardian.getAccountType()).thenReturn(AccountType.STANDALONE);
    return guardian;
  }

  private User authenticatedUserWithId(long id) {
    User user = mock(User.class);
    when(user.getId()).thenReturn(id);
    return user;
  }

  @Test
  void createBuildsManagedProfileOwnedByGuardian() {
    User guardian = standaloneGuardian();

    when(users.findById(7L)).thenReturn(Optional.of(guardian));
    User authenticatedGuardian = authenticatedUserWithId(7L);
    when(currentUser.getAuthenticatedUser()).thenReturn(authenticatedGuardian);
    when(users.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var response = service.create(7L, new ChildProfileRequest("  Léa  "));

    assertThat(response.displayName()).isEqualTo("Léa");

    verify(users)
        .save(
            argThat(
                child ->
                    child.getAccountType() == AccountType.MANAGED
                        && child.getGuardianUserId().equals(7L)));
  }

  @Test
  void updateRejectsChildOwnedByAnotherGuardian() {
    User guardian = standaloneGuardian();

    User child = new User("Léa", AccountType.MANAGED);
    child.setGuardianUserId(99L);

    when(users.findById(7L)).thenReturn(Optional.of(guardian));
    User authenticatedGuardian = authenticatedUserWithId(7L);
    when(currentUser.getAuthenticatedUser()).thenReturn(authenticatedGuardian);
    when(users.findById(12L)).thenReturn(Optional.of(child));

    assertThatThrownBy(() -> service.update(7L, 12L, new ChildProfileRequest("Nouveau nom")))
        .isInstanceOf(ResponseStatusException.class)
        .hasMessageContaining("404 NOT_FOUND");
  }

  @Test
  void deleteRemovesChildOwnedByGuardian() {
    User guardian = standaloneGuardian();
    User child = new User("Léa", AccountType.MANAGED);
    child.setGuardianUserId(7L);

    when(users.findById(7L)).thenReturn(Optional.of(guardian));
    User authenticatedGuardian = authenticatedUserWithId(7L);
    when(currentUser.getAuthenticatedUser()).thenReturn(authenticatedGuardian);
    when(users.findById(12L)).thenReturn(Optional.of(child));

    service.delete(7L, 12L);

    verify(users).delete(child);
  }

  @Test
  void listRejectsWhenAuthenticatedUserIsNotTheRequestedGuardian() {
    User targetGuardian = standaloneGuardian();

    when(users.findById(7L)).thenReturn(Optional.of(targetGuardian));
    User attacker = authenticatedUserWithId(99L);
    when(currentUser.getAuthenticatedUser()).thenReturn(attacker);

    assertThatThrownBy(() -> service.list(7L))
        .isInstanceOf(ResponseStatusException.class)
        .hasMessageContaining("404 NOT_FOUND");

    verify(users, never()).findAllByGuardianUserIdOrderByDisplayNameAsc(any());
  }
}
