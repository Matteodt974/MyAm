package com.uqam.inm5151.scan.repository;

import com.uqam.inm5151.scan.domain.ProfileShare;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProfileShareRepository extends JpaRepository<ProfileShare, Long> {
  Optional<ProfileShare> findByShareToken(String shareToken);
}
