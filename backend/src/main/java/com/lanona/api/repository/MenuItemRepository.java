package com.lanona.api.repository;

import com.lanona.api.entity.MenuItem;
import com.lanona.api.entity.MenuItemStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface MenuItemRepository extends JpaRepository<MenuItem, UUID> {

    @Query("""
            SELECT m FROM MenuItem m
            WHERE (:category IS NULL OR LOWER(m.category.name) = LOWER(CAST(:category AS string)))
              AND (:status IS NULL OR m.status = :status)
              AND (:query IS NULL OR LOWER(m.name) LIKE LOWER(CONCAT('%', CAST(:query AS string), '%')))
            ORDER BY m.createdAt DESC
            """)
    List<MenuItem> search(
            @Param("category") String category,
            @Param("status") MenuItemStatus status,
            @Param("query") String query);

    @Query("SELECT DISTINCT m.category.name FROM MenuItem m ORDER BY m.category.name")
    List<String> findDistinctCategoryNames();

    long countByCategoryId(UUID categoryId);
}
