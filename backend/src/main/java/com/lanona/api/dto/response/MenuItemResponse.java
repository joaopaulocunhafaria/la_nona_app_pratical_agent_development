package com.lanona.api.dto.response;

import com.lanona.api.entity.MenuCategory;
import com.lanona.api.entity.MenuItem;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

public record MenuItemResponse(
        UUID id,
        String name,
        String description,
        BigDecimal price,
        String category,
        boolean available,
        List<MenuItemImageResponse> images,
        Instant createdAt,
        Instant updatedAt
) {

    public static MenuItemResponse from(MenuItem item) {
        List<MenuItemImageResponse> images = item.getImages().stream()
                .sorted(Comparator.comparingInt(image -> image.getPosition()))
                .map(MenuItemImageResponse::from)
                .toList();

        return new MenuItemResponse(
                item.getId(),
                item.getName(),
                item.getDescription(),
                item.getPrice(),
                displayName(item.getCategory()),
                item.isAvailable(),
                images,
                item.getCreatedAt(),
                item.getUpdatedAt()
        );
    }

    private static String displayName(MenuCategory category) {
        String lower = category.name().toLowerCase();
        return lower.substring(0, 1).toUpperCase() + lower.substring(1);
    }
}
