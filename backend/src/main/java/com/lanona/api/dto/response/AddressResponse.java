package com.lanona.api.dto.response;

import com.lanona.api.entity.User;

public record AddressResponse(
        String cep,
        String rua,
        String bairro,
        String numero,
        String cidade,
        String estado,
        String complemento
) {

    public static AddressResponse from(User user) {
        return new AddressResponse(
                user.getAddressCep(),
                user.getAddressRua(),
                user.getAddressBairro(),
                user.getAddressNumero(),
                user.getAddressCidade(),
                user.getAddressEstado(),
                user.getAddressComplemento()
        );
    }
}
