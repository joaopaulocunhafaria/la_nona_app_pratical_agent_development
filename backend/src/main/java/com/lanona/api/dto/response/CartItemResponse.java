package com.lanona.api.dto.response;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record CartItemResponse(
        UUID id,
        MenuItemResponse menuItem,
        int quantity,
        Instant addedAt,
        BigDecimal subtotal
) {
}
