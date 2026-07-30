package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

@ExtendWith(MockitoExtension.class)
class UserDetailsServiceImplTest {

  private static final String EMAIL = "user@test.com";
  private static final String PASSWORD_HASH = "hashed_secret";

  @Mock private UserRepository userRepository;

  private UserDetailsServiceImpl service() {
    return new UserDetailsServiceImpl(userRepository);
  }

  private User testUser() {
    User user = new User("Test User", AccountType.STANDALONE);
    user.setEmail(EMAIL);
    user.setPasswordHash(PASSWORD_HASH);
    return user;
  }

  @Test
  void loadUserByUsername_whenUserExists_returnsUserDetailsWithRoleUser() {
    when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(testUser()));

    UserDetails userDetails = service().loadUserByUsername(EMAIL);

    assertThat(userDetails.getUsername()).isEqualTo(EMAIL);
    assertThat(userDetails.getPassword()).isEqualTo(PASSWORD_HASH);
    assertThat(userDetails.getAuthorities())
        .extracting("authority")
        .containsExactly("ROLE_USER");
    verify(userRepository).findByEmail(EMAIL);
  }

  @Test
  void loadUserByUsername_whenUserNotFound_throwsUsernameNotFoundException() {
    when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service().loadUserByUsername(EMAIL))
        .isInstanceOf(UsernameNotFoundException.class);
    verify(userRepository).findByEmail(EMAIL);
  }
}