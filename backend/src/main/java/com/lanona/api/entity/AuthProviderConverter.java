package com.lanona.api.entity;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * Mapeia o enum AuthProvider para os valores em minusculo aceitos pelo
 * CHECK constraint da coluna users.provider ('local', 'google').
 */
@Converter
public class AuthProviderConverter implements AttributeConverter<AuthProvider, String> {

    @Override
    public String convertToDatabaseColumn(AuthProvider attribute) {
        return attribute == null ? null : attribute.name().toLowerCase();
    }

    @Override
    public AuthProvider convertToEntityAttribute(String dbData) {
        return dbData == null ? null : AuthProvider.valueOf(dbData.toUpperCase());
    }
}
