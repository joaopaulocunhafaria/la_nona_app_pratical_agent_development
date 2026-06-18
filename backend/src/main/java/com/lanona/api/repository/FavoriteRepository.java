package com.lanona.api.repository;

import com.lanona.api.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FavoriteRepository extends JpaRepository<Favorite, UUID> {

    List<Favorite> findByUserIdOrderByCreatedAtDesc(UUID userId);

    Optional<Favorite> findByUserIdAndMenuItemId(UUID userId, UUID menuItemId);

    void deleteByUserIdAndMenuItemId(UUID userId, UUID menuItemId);
}
