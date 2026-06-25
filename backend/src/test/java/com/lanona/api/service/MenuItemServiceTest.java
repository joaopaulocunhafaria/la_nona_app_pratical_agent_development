package com.lanona.api.service;

import com.lanona.api.dto.request.MenuItemImageRequest;
import com.lanona.api.dto.request.MenuItemRequest;
import com.lanona.api.dto.response.MenuItemResponse;
import com.lanona.api.entity.MenuCategory;
import com.lanona.api.entity.MenuItem;
import com.lanona.api.entity.MenuItemImage;
import com.lanona.api.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MenuItemServiceTest {

    @Mock
    private com.lanona.api.repository.MenuItemRepository menuItemRepository;

    @Mock
    private S3StorageService storageService;

    @InjectMocks
    private MenuItemService menuItemService;

    @BeforeEach
    void setUp() {
        lenient().when(menuItemRepository.saveAndFlush(any(MenuItem.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void create_uploadsNewImageAndStoresOnlyUrl() {
        when(storageService.uploadBase64(eq("Zm9v"), eq("image/jpeg"), eq("menu-items")))
                .thenReturn("https://bucket/menu-items/new.jpg");

        MenuItemRequest request = new MenuItemRequest(
                "X-Burguer", "Pao e carne", new BigDecimal("29.90"), "hamburguer", true,
                List.of(new MenuItemImageRequest(null, "Zm9v", "image/jpeg")));

        MenuItemResponse response = menuItemService.create(request);

        assertThat(response.images()).hasSize(1);
        assertThat(response.images().get(0).url()).isEqualTo("https://bucket/menu-items/new.jpg");
        verify(storageService).uploadBase64("Zm9v", "image/jpeg", "menu-items");
    }

    @Test
    void create_rejectsImageWithoutUrlOrBase64() {
        MenuItemRequest request = new MenuItemRequest(
                "X-Burguer", "Pao e carne", new BigDecimal("10.00"), "pizza", true,
                List.of(new MenuItemImageRequest(null, null, null)));

        assertThatThrownBy(() -> menuItemService.create(request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Imagem inválida");
        verify(storageService, never()).uploadBase64(any(), any(), any());
    }

    @Test
    void update_keepsExistingUrl_uploadsNew_andDeletesRemovedImage() {
        UUID id = UUID.randomUUID();
        MenuItem existing = MenuItem.builder()
                .id(id)
                .name("Velho")
                .description("desc")
                .price(new BigDecimal("10.00"))
                .category(MenuCategory.PIZZA)
                .available(true)
                .images(new ArrayList<>())
                .build();
        existing.getImages().add(MenuItemImage.builder()
                .menuItem(existing).imageUrl("https://bucket/menu-items/kept.jpg").position(0).build());
        existing.getImages().add(MenuItemImage.builder()
                .menuItem(existing).imageUrl("https://bucket/menu-items/removed.jpg").position(1).build());

        when(menuItemRepository.findById(id)).thenReturn(Optional.of(existing));
        when(storageService.uploadBase64(eq("Yml0"), eq("image/png"), eq("menu-items")))
                .thenReturn("https://bucket/menu-items/added.png");

        MenuItemRequest request = new MenuItemRequest(
                "Novo Nome", "nova desc", new BigDecimal("12.00"), "pizza", true,
                List.of(
                        new MenuItemImageRequest("https://bucket/menu-items/kept.jpg", null, null),
                        new MenuItemImageRequest(null, "Yml0", "image/png")));

        MenuItemResponse response = menuItemService.update(id, request);

        assertThat(response.images()).extracting(img -> img.url())
                .containsExactly("https://bucket/menu-items/kept.jpg", "https://bucket/menu-items/added.png");
        // a imagem que saiu do item e' removida do bucket; a mantida nao.
        verify(storageService).delete("https://bucket/menu-items/removed.jpg");
        verify(storageService, never()).delete("https://bucket/menu-items/kept.jpg");
    }

    @Test
    void delete_removesItemImagesFromBucket() {
        UUID id = UUID.randomUUID();
        MenuItem existing = MenuItem.builder()
                .id(id).name("X").description("d").price(new BigDecimal("1.00"))
                .category(MenuCategory.BEBIDA).available(true).images(new ArrayList<>())
                .build();
        existing.getImages().add(MenuItemImage.builder()
                .menuItem(existing).imageUrl("https://bucket/menu-items/a.jpg").position(0).build());
        when(menuItemRepository.findById(id)).thenReturn(Optional.of(existing));

        menuItemService.delete(id);

        verify(menuItemRepository).delete(existing);
        verify(storageService).delete("https://bucket/menu-items/a.jpg");
    }
}
