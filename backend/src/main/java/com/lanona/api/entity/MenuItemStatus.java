package com.lanona.api.entity;

/**
 * Situacao de um item do cardapio. Substitui o antigo booleano {@code available},
 * permitindo estados intermediarios alem de disponivel/indisponivel.
 *
 * <p>Todos os estados, exceto {@link #INDISPONIVEL}, permitem que o cliente
 * adicione o item ao carrinho (ver {@link #isOrderable()}).</p>
 */
public enum MenuItemStatus {

    /** Pronto para pedido imediato. */
    DISPONIVEL,

    /** Preparado sob demanda no momento do pedido. */
    FEITO_NA_HORA,

    /** Disponibilidade incerta; o cliente deve confirmar antes/ao pedir. */
    VERIFICAR_DISPONIBILIDADE,

    /** Sem disponibilidade; nao pode ser adicionado ao carrinho. */
    INDISPONIVEL;

    /** Indica se o item pode ser adicionado ao carrinho neste estado. */
    public boolean isOrderable() {
        return this != INDISPONIVEL;
    }
}
