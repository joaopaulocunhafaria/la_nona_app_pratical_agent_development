package com.lanona.api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record GoogleLoginRequest(
        @NotBlank(message = "idToken é obrigatório")
        String idToken
) {
}
