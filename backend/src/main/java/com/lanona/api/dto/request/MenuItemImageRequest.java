package com.lanona.api.dto.request;

/**
 * Imagem de um item de cardapio enviada pelo cliente. Pode representar:
 * <ul>
 *   <li>uma imagem <b>nova</b> a enviar para o bucket: {@code base64} + {@code contentType};</li>
 *   <li>uma imagem <b>ja' existente</b> a manter na edicao: apenas {@code url}
 *       (URL publica devolvida anteriormente pela API).</li>
 * </ul>
 * A validacao de "exatamente um dos dois" e' feita em {@code MenuItemService}.
 */
public record MenuItemImageRequest(
        String url,
        String base64,
        String contentType
) {

    /** {@code true} quando o cliente esta' apenas mantendo uma imagem ja' armazenada. */
    public boolean isExisting() {
        return url != null && !url.isBlank();
    }
}
