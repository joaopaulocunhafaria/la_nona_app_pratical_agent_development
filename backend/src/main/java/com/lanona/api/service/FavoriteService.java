package com.lanona.api.service;

import com.lanona.api.dto.response.MenuItemResponse;
import com.lanona.api.entity.Favorite;
import com.lanona.api.entity.MenuItem;
import com.lanona.api.exception.ResourceNotFoundException;
import com.lanona.api.repository.FavoriteRepository;
import com.lanona.api.repository.MenuItemRepository;
import com.lanona.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final MenuItemRepository menuItemRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<MenuItemResponse> list(UUID userId) {
        return favoriteRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(favorite -> MenuItemResponse.from(favorite.getMenuItem()))
                .toList();
    }

    @Transactional
    public void add(UUID userId, UUID menuItemId) {
        if (favoriteRepository.findByUserIdAndMenuItemId(userId, menuItemId).isPresent()) {
            return;
        }

        MenuItem menuItem = menuItemRepository.findById(menuItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Item de cardápio não encontrado."));

        Favorite favorite = Favorite.builder()
                .user(userRepository.getReferenceById(userId))
                .menuItem(menuItem)
                .build();

        favoriteRepository.save(favorite);
    }

    @Transactional
    public void remove(UUID userId, UUID menuItemId) {
        favoriteRepository.deleteByUserIdAndMenuItemId(userId, menuItemId);
    }
}
