package com.lanona.api.repository;

import com.lanona.api.entity.MenuItemImage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface MenuItemImageRepository extends JpaRepository<MenuItemImage, UUID> {
}
