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
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(
    name = "scan_history",
    indexes = @Index(name = "idx_scan_history_user_time", columnList = "user_id, scanned_at"))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ScanHistory {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "user_id", nullable = false)
  private Long userId;

  @Enumerated(EnumType.STRING)
  @Column(name = "scan_type", nullable = false)
  private ScanType scanType;

  @Column(nullable = false)
  private String title;

  @Column(name = "scanned_at", nullable = false)
  private Instant scannedAt;

  @Column(name = "risk_level")
  private String riskLevel;

  @ElementCollection
  @CollectionTable(
      name = "scan_history_matched_allergens",
      joinColumns = @JoinColumn(name = "scan_history_id"))
  @OrderColumn(name = "position")
  @Column(name = "allergen")
  private List<String> matchedAllergens = new ArrayList<>();

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "raw_json", nullable = false)
  private String rawJson;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  public ScanHistory(
      Long userId,
      ScanType scanType,
      String title,
      Instant scannedAt,
      String riskLevel,
      List<String> matchedAllergens,
      String rawJson) {
    this.userId = userId;
    this.scanType = scanType;
    this.title = title;
    this.scannedAt = scannedAt;
    this.riskLevel = riskLevel;
    this.matchedAllergens = matchedAllergens != null ? matchedAllergens : new ArrayList<>();
    this.rawJson = rawJson;
    this.createdAt = Instant.now();
  }
}
