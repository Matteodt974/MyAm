package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CurrentUserService {
  private final UserRepository users;

  public CurrentUserService(UserRepository users) {
    this.users = users;
  }

  public User getAuthenticatedUser() {
    UserDetails principal =
        (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

    return users
        .findByEmail(principal.getUsername())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
  }
}
