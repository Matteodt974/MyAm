package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.domain.DigestiveJournalEntry;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisRequest;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisRequest.FoodItem;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse;
import com.uqam.inm5151.scan.repository.DigestiveJournalEntryRepository;
import com.uqam.inm5151.scan.repository.UserRepository;
import com.uqam.inm5151.scan.service.IntoleranceRuleEngine.DigestiveEpisode;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Orchestrateur UC-26 : charge et dechiffre les episodes du journal digestif (UC-23), verifie les
 * preconditions du UC puis delegue la correlation au {@link IntoleranceRuleEngine}.
 */
@Service
public class IntoleranceAnalysisService {

  /** Fenetre d'observation des episodes Bristol pris en compte dans l'analyse. */
  static final Duration EPISODE_WINDOW = Duration.ofDays(14);

  /** Fenetre du journal alimentaire imposee par le UC. */
  static final Duration FOOD_WINDOW = Duration.ofHours(72);

  private static final String NO_JOURNAL_ENTRIES_MESSAGE =
      "Aucune entrée dans votre journal digestif. Ajoutez au moins une entrée pour lancer"
          + " l'analyse.";

  private final DigestiveJournalEntryRepository journalRepository;
  private final EncryptionService encryption;
  private final UserRepository users;
  private final IntoleranceRuleEngine ruleEngine;

  public IntoleranceAnalysisService(
      DigestiveJournalEntryRepository journalRepository,
      EncryptionService encryption,
      UserRepository users,
      IntoleranceRuleEngine ruleEngine) {
    this.journalRepository = journalRepository;
    this.encryption = encryption;
    this.users = users;
    this.ruleEngine = ruleEngine;
  }

  public IntoleranceAnalysisResponse analyze(String email, IntoleranceAnalysisRequest request) {
    return analyze(email, request, Instant.now());
  }

  IntoleranceAnalysisResponse analyze(
      String email, IntoleranceAnalysisRequest request, Instant now) {
    Long userId =
        users
            .findByEmail(email)
            .map(User::getId)
            .orElseThrow(
                () ->
                    new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non trouvé"));

    List<DigestiveEpisode> episodes =
        journalRepository
            .findByUserIdAndOccurredAtAfterOrderByOccurredAtDesc(userId, now.minus(EPISODE_WINDOW))
            .stream()
            .map(this::decrypt)
            .toList();

    if (episodes.isEmpty()) {
      return new IntoleranceAnalysisResponse(
          IntoleranceAnalysisResponse.STATUS_NO_JOURNAL_ENTRIES,
          NO_JOURNAL_ENTRIES_MESSAGE,
          null,
          List.of(),
          List.of(),
          IntoleranceRuleEngine.MEDICAL_DISCLAIMER);
    }

    // Defense en profondeur : le frontend filtre deja sur 72 h, on re-filtre cote serveur.
    Instant foodWindowStart = now.minus(FOOD_WINDOW);
    List<FoodItem> recentFood =
        request.foodItems().stream()
            .filter(item -> !item.consumedAt().isBefore(foodWindowStart))
            .toList();

    return ruleEngine.analyze(episodes, recentFood);
  }

  private DigestiveEpisode decrypt(DigestiveJournalEntry entry) {
    int bristolType = Integer.parseInt(encryption.decrypt(entry.getBristolTypeEncrypted()));
    return new DigestiveEpisode(entry.getOccurredAt(), bristolType);
  }
}
