package com.lanona.api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "Email não pode estar vazio")
        String email,

        @NotBlank(message = "Senha não pode estar vazia")
        String password
) {
}
