package com.uqam.inm5151.scan.repository;

import com.uqam.inm5151.scan.domain.DigestiveJournalEntry;
import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DigestiveJournalEntryRepository
    extends JpaRepository<DigestiveJournalEntry, Long> {
  List<DigestiveJournalEntry> findByUserIdAndOccurredAtAfterOrderByOccurredAtDesc(
      Long userId, Instant since);

  List<DigestiveJournalEntry> findByUserIdOrderByOccurredAtDesc(Long userId);
}
