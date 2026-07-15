package com.uqam.inm5151.scan.domain;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.Check;

@Entity
@Table(name = "users")
@Check(
    constraints =
        "(account_type = 'STANDALONE' AND email IS NOT NULL AND "
            + "password_hash IS NOT NULL)"
            + " OR (account_type = 'MANAGED' AND guardian_user_id IS NOT NULL AND "
            + "email IS NULL"
            + " AND password_hash IS NULL)")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(exclude = "passwordHash")
public class User {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Setter
  @Column(unique = true)
  private String email;

  @Setter
  @Column(name = "password_hash")
  private String passwordHash;

  @Setter
  @Column(name = "display_name", nullable = false)
  private String displayName;

  @Enumerated(EnumType.STRING)
  @Column(name = "account_type", nullable = false)
  private AccountType accountType;

  @Setter
  @Column(name = "guardian_user_id")
  private Long guardianUserId;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @ElementCollection
  @CollectionTable(name = "user_allergies", joinColumns = @JoinColumn(name = "user_id"))
  @Column(name = "allergen_code")
  private Set<String> allergies = new HashSet<>();

  @ElementCollection
  @CollectionTable(name = "user_diets", joinColumns = @JoinColumn(name = "user_id"))
  @Column(name = "diet")
  private Set<String> diets = new HashSet<>();

  public User(String displayName, AccountType accountType) {
    this.displayName = displayName;
    this.accountType = accountType;
    this.createdAt = Instant.now();
    this.updatedAt = Instant.now();
  }
}
