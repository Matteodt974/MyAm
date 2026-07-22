package com.uqam.inm5151.scan.domain;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserCheckConstraintTest {
  @Autowired private EntityManager entityManager;

  @DynamicPropertySource
  static void postgresProperties(DynamicPropertyRegistry registry) {
    // Port 5433 car Docker Compose expose PostgreSQL sur 127.0.0.1:5433 (pas 5432).
    registry.add("spring.datasource.url", () -> "jdbc:postgresql://localhost:5433/scan");
    registry.add("spring.datasource.username", () -> "scan");
    registry.add("spring.datasource.password", () -> "scan");
    registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
    registry.add("spring.jpa.database-platform", () -> "org.hibernate.dialect.PostgreSQLDialect");
  }

  @Test
  void standaloneWithoutPasswordHashIsRejected() {
    User user = new User("Alex", AccountType.STANDALONE);
    user.setEmail("alex@example.com");
    // password_hash volontairement omis

    assertThatThrownBy(
            () -> {
              entityManager.persist(user);
              entityManager.flush();
            })
        .isInstanceOf(PersistenceException.class);
  }

  @Test
  void managedWithoutGuardianIsRejected() {
    User user = new User("Leo", AccountType.MANAGED);

    assertThatThrownBy(
            () -> {
              entityManager.persist(user);
              entityManager.flush();
            })
        .isInstanceOf(PersistenceException.class);
  }

  @Test
  void managedWithEmailIsRejected() {
    User user = new User("Leo", AccountType.MANAGED);
    user.setGuardianUserId(1L);
    user.setEmail("leo@example.com");

    assertThatThrownBy(
            () -> {
              entityManager.persist(user);
              entityManager.flush();
            })
        .isInstanceOf(PersistenceException.class);
  }

  @Test
  void validStandaloneAndManagedAccountsAreAccepted() {
    User guardian = new User("Parent", AccountType.STANDALONE);
    guardian.setEmail("parent@example.com");
    guardian.setPasswordHash("hashed");
    entityManager.persist(guardian);
    entityManager.flush();

    User child = new User("Enfant", AccountType.MANAGED);
    child.setGuardianUserId(guardian.getId());
    entityManager.persist(child);
    entityManager.flush();
  }
}
