package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.ProfilePreferencesRequest;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class ProfilePreferencesServiceTest {
  @Mock private UserRepository users;

  @Mock private CurrentUserService currentUser;

  @InjectMocks private ProfilePreferencesService service;

  private User authenticatedUserWithId(long id) {
    User user = mock(User.class);
    when(user.getId()).thenReturn(id);
    when(currentUser.getAuthenticatedUser()).thenReturn(user);
    return user;
  }

  private User realUserWithId(long id) {
    User user = new User("Profil", AccountType.STANDALONE);
    org.springframework.test.util.ReflectionTestUtils.setField(user, "id", id);
    return user;
  }

  @Test
  void replaceNormalizesAllergiesAndDiets() {
    User account = realUserWithId(7L);
    when(currentUser.getAuthenticatedUser()).thenReturn(account);
    when(users.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var response =
        service.replace(
            7L, new ProfilePreferencesRequest(Set.of("  Arachide ", "LAIT"), Set.of("vegan")));

    assertThat(response.allergies()).containsExactlyInAnyOrder("arachide", "lait");
    assertThat(response.diets()).containsExactly("VEGAN");
  }

  @Test
  void replaceOverwritesPreviousPreferences() {
    User account = realUserWithId(7L);
    account.replacePreferences(Set.of("gluten"), Set.of("HALAL"));
    when(currentUser.getAuthenticatedUser()).thenReturn(account);
    when(users.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var response = service.replace(7L, new ProfilePreferencesRequest(Set.of("arachide"), Set.of()));

    assertThat(response.allergies()).containsExactly("arachide");
    assertThat(response.diets()).isEmpty();
  }

  @Test
  void replaceRejectsUnknownDiet() {
    User account = realUserWithId(7L);
    when(currentUser.getAuthenticatedUser()).thenReturn(account);

    assertThatThrownBy(
            () ->
                service.replace(
                    7L, new ProfilePreferencesRequest(Set.of(), Set.of("CARNIVORE_STRICT"))))
        .isInstanceOf(ResponseStatusException.class)
        .hasMessageContaining("400 BAD_REQUEST");

    verify(users, never()).save(any(User.class));
  }

  @Test
  void getReadsChildProfileOwnedByGuardian() {
    authenticatedUserWithId(7L);
    User child = new User("Léa", AccountType.MANAGED);
    child.setGuardianUserId(7L);
    child.replacePreferences(Set.of("lait"), Set.of("LACTOSE_FREE"));
    when(users.findById(12L)).thenReturn(Optional.of(child));

    var response = service.get(12L);

    assertThat(response.allergies()).containsExactly("lait");
    assertThat(response.diets()).containsExactly("LACTOSE_FREE");
  }

  @Test
  void getRejectsProfileOwnedByAnotherGuardian() {
    authenticatedUserWithId(99L);
    User child = new User("Léa", AccountType.MANAGED);
    child.setGuardianUserId(7L);
    when(users.findById(12L)).thenReturn(Optional.of(child));

    assertThatThrownBy(() -> service.get(12L))
        .isInstanceOf(ResponseStatusException.class)
        .hasMessageContaining("403 FORBIDDEN");
  }

  @Test
  void getRejectsUnknownProfile() {
    authenticatedUserWithId(7L);
    when(users.findById(12L)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.get(12L))
        .isInstanceOf(ResponseStatusException.class)
        .hasMessageContaining("404 NOT_FOUND");
  }
}
