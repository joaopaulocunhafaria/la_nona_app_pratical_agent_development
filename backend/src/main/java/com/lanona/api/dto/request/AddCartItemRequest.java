package com.lanona.api.dto.request;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record AddCartItemRequest(
        @NotNull(message = "menuItemId é obrigatório")
        UUID menuItemId,

        Integer quantity
) {
}
