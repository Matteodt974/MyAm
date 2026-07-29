package com.uqam.inm5151.scan.repository;

import com.uqam.inm5151.scan.domain.DigestiveJournalEntry;
import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DigestiveJournalEntryRepository
    extends JpaRepository<DigestiveJournalEntry, Long> {
  @Query(
      """
      select e from DigestiveJournalEntry e
      where e.userId = :userId
        and (e.profileId = :profileId or (e.profileId is null and e.userId = :profileId))
        and e.occurredAt > :since
      order by e.occurredAt desc
      """)
  List<DigestiveJournalEntry> findForProfileSince(
      @Param("userId") Long userId,
      @Param("profileId") Long profileId,
      @Param("since") Instant since);

  /** Plafonnee a 1000 entrees pour eviter une reponse non bornee sur /v1/digestive-journal. */
  @Query(
      """
      select e from DigestiveJournalEntry e
      where e.userId = :userId
        and (e.profileId = :profileId or (e.profileId is null and e.userId = :profileId))
      order by e.occurredAt desc
      limit 1000
      """)
  List<DigestiveJournalEntry> findForProfile(
      @Param("userId") Long userId, @Param("profileId") Long profileId);
}
