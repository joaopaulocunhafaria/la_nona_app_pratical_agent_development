package com.lanona.api.entity;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * Mapeia o enum MenuCategory para os valores aceitos pelo CHECK constraint
 * da coluna menu_items.category ('Hamburguer', 'Pizza', ... - primeira
 * letra maiuscula, resto minusculo).
 */
@Converter
public class MenuCategoryConverter implements AttributeConverter<MenuCategory, String> {

    @Override
    public String convertToDatabaseColumn(MenuCategory attribute) {
        if (attribute == null) {
            return null;
        }
        String lower = attribute.name().toLowerCase();
        return lower.substring(0, 1).toUpperCase() + lower.substring(1);
    }

    @Override
    public MenuCategory convertToEntityAttribute(String dbData) {
        return dbData == null ? null : MenuCategory.valueOf(dbData.toUpperCase());
    }
}
