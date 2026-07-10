package com.lanona.api.repository;

import com.lanona.api.entity.TelemetrySession;
import com.lanona.api.repository.projection.UserDurationProjection;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface TelemetrySessionRepository extends JpaRepository<TelemetrySession, UUID> {

    /** Sessoes logadas ainda ativas (sem fim e vistas recentemente). */
    long countByEndedAtIsNullAndUserIsNotNullAndLastSeenAtAfter(Instant threshold);

    /** Sessoes anonimas ainda ativas (sem fim e vistas recentemente). */
    long countByEndedAtIsNullAndUserIsNullAndLastSeenAtAfter(Instant threshold);

    /** Media de tempo ativo (segundos) das sessoes iniciadas no periodo. */
    @Query("""
            SELECT COALESCE(AVG(s.activeSeconds), 0)
            FROM TelemetrySession s
            WHERE s.startedAt BETWEEN :from AND :to
            """)
    double averageActiveSeconds(@Param("from") Instant from, @Param("to") Instant to);

    /** Quantidade de sessoes iniciadas no periodo. */
    long countByStartedAtBetween(Instant from, Instant to);

    /**
     * Ranking de tempo de acesso por usuario (logados agrupados por user_id,
     * anonimos agrupados por anonymous_id), do maior para o menor.
     */
    @Query(value = """
            SELECT u.name AS userName,
                   MIN(s.anonymous_id) AS anonymousId,
                   bool_or(s.user_id IS NULL) AS anonymous,
                   SUM(s.active_seconds) AS totalActiveSeconds,
                   COUNT(*) AS sessionCount
            FROM telemetry_sessions s
            LEFT JOIN users u ON u.id = s.user_id
            WHERE s.started_at BETWEEN :from AND :to
            GROUP BY COALESCE(CAST(s.user_id AS varchar), s.anonymous_id), u.name
            ORDER BY totalActiveSeconds DESC
            """, nativeQuery = true)
    List<UserDurationProjection> rankUserDurations(
            @Param("from") Instant from, @Param("to") Instant to, Pageable pageable);
}
