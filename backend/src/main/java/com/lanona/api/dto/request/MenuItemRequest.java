package com.lanona.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;

public record MenuItemRequest(
        @NotBlank(message = "Nome é obrigatório")
        String name,

        @NotBlank(message = "Descrição é obrigatória")
        String description,

        @NotNull(message = "Preço é obrigatório")
        @DecimalMin(value = "0.0", inclusive = false, message = "Preço deve ser um número válido maior que 0")
        BigDecimal price,

        @NotBlank(message = "Selecione uma categoria")
        String category,

        Boolean available,

        @NotEmpty(message = "Adicione pelo menos uma imagem")
        List<@Valid MenuItemImageRequest> images
) {
}
