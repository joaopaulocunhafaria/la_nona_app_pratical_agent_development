package com.lanona.api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record SendChatMessageRequest(
        @NotBlank(message = "Mensagem não pode estar vazia")
        String text
) {
}
