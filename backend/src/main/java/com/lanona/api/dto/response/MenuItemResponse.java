package com.lanona.api.dto.response;

import com.lanona.api.entity.MenuItem;
import com.lanona.api.entity.MenuItemStatus;

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
        UUID categoryId,
        MenuItemStatus status,
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
                item.getCategory().getName(),
                item.getCategory().getId(),
                item.getStatus(),
                images,
                item.getCreatedAt(),
                item.getUpdatedAt()
        );
    }
}
