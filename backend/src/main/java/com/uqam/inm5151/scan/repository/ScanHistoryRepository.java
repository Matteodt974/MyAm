package com.uqam.inm5151.scan.repository;

import com.uqam.inm5151.scan.domain.ScanHistory;
import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ScanHistoryRepository extends JpaRepository<ScanHistory, Long> {
  List<ScanHistory> findByUserIdAndScannedAtAfterOrderByScannedAtDesc(Long userId, Instant since);
}
