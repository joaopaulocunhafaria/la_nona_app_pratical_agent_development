package com.lanona.api.dto.request;

/**
 * Registro de um acesso a aba de cardapio. anonymousId identifica o cliente
 * anonimo; ambos os campos sao opcionais (o usuario logado e' associado via
 * JWT e a plataforma pode vir do header X-Client-Platform).
 */
public record MenuViewRequest(
        String anonymousId,

        String platform
) {
}
