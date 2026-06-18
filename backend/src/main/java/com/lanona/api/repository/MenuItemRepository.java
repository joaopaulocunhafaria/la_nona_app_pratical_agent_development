package com.lanona.api.repository;

import com.lanona.api.entity.MenuCategory;
import com.lanona.api.entity.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface MenuItemRepository extends JpaRepository<MenuItem, UUID> {

    @Query("""
            SELECT m FROM MenuItem m
            WHERE (:category IS NULL OR m.category = :category)
              AND (:available IS NULL OR m.available = :available)
              AND (:query IS NULL OR LOWER(m.name) LIKE LOWER(CONCAT('%', CAST(:query AS string), '%')))
            ORDER BY m.createdAt DESC
            """)
    List<MenuItem> search(
            @Param("category") MenuCategory category,
            @Param("available") Boolean available,
            @Param("query") String query);
}
