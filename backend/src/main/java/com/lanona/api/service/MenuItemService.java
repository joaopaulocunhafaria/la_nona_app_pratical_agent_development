package com.lanona.api.service;

import com.lanona.api.dto.request.MenuItemImageRequest;
import com.lanona.api.dto.request.MenuItemRequest;
import com.lanona.api.dto.response.MenuItemResponse;
import com.lanona.api.entity.MenuCategory;
import com.lanona.api.entity.MenuItem;
import com.lanona.api.entity.MenuItemImage;
import com.lanona.api.exception.BadRequestException;
import com.lanona.api.exception.ResourceNotFoundException;
import com.lanona.api.repository.MenuItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MenuItemService {

    private final MenuItemRepository menuItemRepository;

    @Transactional(readOnly = true)
    public List<MenuItemResponse> search(String category, Boolean available, String query) {
        MenuCategory categoryEnum = (category == null || category.isBlank()) ? null : parseCategory(category);
        String normalizedQuery = (query == null || query.isBlank()) ? null : query.trim();

        return menuItemRepository.search(categoryEnum, available, normalizedQuery).stream()
                .map(MenuItemResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public MenuItemResponse getById(UUID id) {
        return MenuItemResponse.from(findById(id));
    }

    @Transactional
    public MenuItemResponse create(MenuItemRequest request) {
        MenuItem item = MenuItem.builder()
                .name(request.name().trim())
                .description(request.description().trim())
                .price(request.price())
                .category(parseCategory(request.category()))
                .available(request.available() == null || request.available())
                .build();

        applyImages(item, request.images());

        return MenuItemResponse.from(menuItemRepository.saveAndFlush(item));
    }

    @Transactional
    public MenuItemResponse update(UUID id, MenuItemRequest request) {
        MenuItem item = findById(id);

        item.setName(request.name().trim());
        item.setDescription(request.description().trim());
        item.setPrice(request.price());
        item.setCategory(parseCategory(request.category()));
        item.setAvailable(request.available() == null || request.available());

        item.getImages().clear();
        applyImages(item, request.images());

        return MenuItemResponse.from(menuItemRepository.saveAndFlush(item));
    }

    @Transactional
    public void delete(UUID id) {
        menuItemRepository.delete(findById(id));
    }

    private void applyImages(MenuItem item, List<MenuItemImageRequest> imageRequests) {
        for (int i = 0; i < imageRequests.size(); i++) {
            MenuItemImageRequest request = imageRequests.get(i);
            item.getImages().add(MenuItemImage.builder()
                    .menuItem(item)
                    .imageData("data:" + request.contentType() + ";base64," + request.base64())
                    .position(i)
                    .build());
        }
    }

    private MenuItem findById(UUID id) {
        return menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Item de cardápio não encontrado."));
    }

    private MenuCategory parseCategory(String raw) {
        try {
            return MenuCategory.valueOf(raw.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BadRequestException(
                    "Categoria inválida. Use: Hamburguer, Pizza, Salada, Bebida, Sobremesa, Acompanhamento ou Outro.");
        }
    }
}
