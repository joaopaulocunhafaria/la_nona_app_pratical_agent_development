package com.lanona.api.dto.response;

import com.lanona.api.entity.MenuItemImage;

import java.util.UUID;

public record MenuItemImageResponse(
        UUID id,
        String url,
        int position
) {

    public static MenuItemImageResponse from(MenuItemImage image) {
        return new MenuItemImageResponse(image.getId(), image.getImageUrl(), image.getPosition());
    }
}
