package com.lanona.api.repository;

import com.lanona.api.entity.MenuViewEvent;
import com.lanona.api.repository.projection.TimeBucketProjection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface MenuViewEventRepository extends JpaRepository<MenuViewEvent, UUID> {

    /** Total de acessos ao cardapio no periodo. */
    long countByCreatedAtBetween(Instant from, Instant to);

    /**
     * Serie temporal de acessos ao cardapio agrupada por hora ou dia.
     * :granularity deve ser um valor aceito por date_trunc ('hour' ou 'day').
     */
    @Query(value = """
            SELECT date_trunc(:granularity, created_at) AS bucket, COUNT(*) AS count
            FROM menu_view_events
            WHERE created_at BETWEEN :from AND :to
            GROUP BY bucket
            ORDER BY bucket
            """, nativeQuery = true)
    List<TimeBucketProjection> menuViewsOverTime(
            @Param("granularity") String granularity,
            @Param("from") Instant from,
            @Param("to") Instant to);
}
