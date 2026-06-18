package com.lanona.api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record MenuItemImageRequest(
        @NotBlank(message = "Imagem: base64 é obrigatório")
        String base64,

        @NotBlank(message = "Imagem: contentType é obrigatório")
        String contentType
) {
}
