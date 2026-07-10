package com.lanona.api.service;

import com.lanona.api.dto.request.MenuItemImageRequest;
import com.lanona.api.dto.request.MenuItemRequest;
import com.lanona.api.dto.response.MenuItemResponse;
import com.lanona.api.entity.MenuCategory;
import com.lanona.api.entity.MenuItem;
import com.lanona.api.entity.MenuItemImage;
import com.lanona.api.entity.MenuItemStatus;
import com.lanona.api.exception.BadRequestException;
import com.lanona.api.exception.ResourceNotFoundException;
import com.lanona.api.repository.MenuCategoryRepository;
import com.lanona.api.repository.MenuItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MenuItemService {

    private static final String IMAGE_DIRECTORY = "menu-items";

    private final MenuItemRepository menuItemRepository;
    private final MenuCategoryRepository menuCategoryRepository;
    private final S3StorageService storageService;

    @Transactional(readOnly = true)
    public List<MenuItemResponse> search(String category, MenuItemStatus status, String query) {
        String normalizedCategory = (category == null || category.isBlank()) ? null : category.trim();
        String normalizedQuery = (query == null || query.isBlank()) ? null : query.trim();

        return menuItemRepository.search(normalizedCategory, status, normalizedQuery).stream()
                .map(MenuItemResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<String> listCategories() {
        return menuItemRepository.findDistinctCategoryNames();
    }

    @Transactional(readOnly = true)
    public MenuItemResponse getById(UUID id) {
        return MenuItemResponse.from(findById(id));
    }

    @Transactional
    public MenuItemResponse create(MenuItemRequest request) {
        MenuItem item = MenuItem.builder()
                .name(request.name().trim())
                .description(request.description().trim())
                .price(request.price())
                .category(resolveCategory(request.category()))
                .status(request.status() == null ? MenuItemStatus.DISPONIVEL : request.status())
                .build();

        applyImages(item, request.images());

        return MenuItemResponse.from(menuItemRepository.saveAndFlush(item));
    }

    @Transactional
    public MenuItemResponse update(UUID id, MenuItemRequest request) {
        MenuItem item = findById(id);

        item.setName(request.name().trim());
        item.setDescription(request.description().trim());
        item.setPrice(request.price());
        item.setCategory(resolveCategory(request.category()));
        item.setStatus(request.status() == null ? MenuItemStatus.DISPONIVEL : request.status());

        List<String> previousUrls = item.getImages().stream()
                .map(MenuItemImage::getImageUrl)
                .toList();

        item.getImages().clear();
        applyImages(item, request.images());

        MenuItemResponse response = MenuItemResponse.from(menuItemRepository.saveAndFlush(item));

        // Remove do bucket as imagens que nao fazem mais parte do item, evitando
        // arquivos orfaos. Falha de remocao nao quebra a atualizacao (ver delete()).
        Set<String> keptUrls = new HashSet<>(item.getImages().stream().map(MenuItemImage::getImageUrl).toList());
        previousUrls.stream()
                .filter(previousUrl -> !keptUrls.contains(previousUrl))
                .forEach(storageService::delete);

        return response;
    }

    @Transactional
    public void delete(UUID id) {
        MenuItem item = findById(id);
        List<String> urls = item.getImages().stream().map(MenuItemImage::getImageUrl).toList();
        menuItemRepository.delete(item);
        urls.forEach(storageService::delete);
    }

    private void applyImages(MenuItem item, List<MenuItemImageRequest> imageRequests) {
        // Pré-resolve as URLs (uploads novos vao para o bucket) antes de montar as
        // entidades; somente a URL e' persistida — o binario nunca toca o banco.
        List<String> resolvedUrls = new ArrayList<>(imageRequests.size());
        for (MenuItemImageRequest request : imageRequests) {
            resolvedUrls.add(resolveImageUrl(request));
        }

        for (int i = 0; i < resolvedUrls.size(); i++) {
            item.getImages().add(MenuItemImage.builder()
                    .menuItem(item)
                    .imageUrl(resolvedUrls.get(i))
                    .position(i)
                    .build());
        }
    }

    private String resolveImageUrl(MenuItemImageRequest request) {
        if (request.isExisting()) {
            return request.url().trim();
        }
        if (request.base64() == null || request.base64().isBlank()
                || request.contentType() == null || request.contentType().isBlank()) {
            throw new BadRequestException("Imagem inválida: informe uma URL existente ou base64 + contentType.");
        }
        return storageService.uploadBase64(request.base64(), request.contentType(), IMAGE_DIRECTORY);
    }

    private MenuItem findById(UUID id) {
        return menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Item de cardápio não encontrado."));
    }

    /**
     * Resolve a categoria informada na requisicao. Aceita tanto o id (UUID)
     * quanto o nome da categoria (case-insensitive), mantendo compatibilidade
     * com clientes que ainda enviam o nome (ex.: app Flutter).
     */
    private MenuCategory resolveCategory(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new BadRequestException("Selecione uma categoria.");
        }
        String value = raw.trim();
        try {
            UUID id = UUID.fromString(value);
            return menuCategoryRepository.findById(id)
                    .orElseThrow(() -> new BadRequestException("Categoria não encontrada."));
        } catch (IllegalArgumentException notUuid) {
            return menuCategoryRepository.findByNameIgnoreCase(value)
                    .orElseThrow(() -> new BadRequestException(
                            "Categoria inválida. Cadastre a categoria antes de vinculá-la a um item."));
        }
    }
}
