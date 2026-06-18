package com.lanona.api.repository;

import com.lanona.api.entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CartItemRepository extends JpaRepository<CartItem, UUID> {

    List<CartItem> findByUserIdOrderByAddedAtDesc(UUID userId);

    Optional<CartItem> findByUserIdAndMenuItemId(UUID userId, UUID menuItemId);

    void deleteByUserIdAndMenuItemId(UUID userId, UUID menuItemId);

    void deleteByUserId(UUID userId);
}
