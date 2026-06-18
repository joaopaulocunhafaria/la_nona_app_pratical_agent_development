package com.lanona.api.service;

import com.lanona.api.dto.request.AddCartItemRequest;
import com.lanona.api.dto.response.CartItemResponse;
import com.lanona.api.dto.response.CartResponse;
import com.lanona.api.dto.response.MenuItemResponse;
import com.lanona.api.entity.CartItem;
import com.lanona.api.entity.MenuItem;
import com.lanona.api.exception.BadRequestException;
import com.lanona.api.exception.ResourceNotFoundException;
import com.lanona.api.repository.CartItemRepository;
import com.lanona.api.repository.MenuItemRepository;
import com.lanona.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CartService {

    private final CartItemRepository cartItemRepository;
    private final MenuItemRepository menuItemRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public CartResponse getCart(UUID userId) {
        return buildCartResponse(userId);
    }

    @Transactional
    public CartResponse addItem(UUID userId, AddCartItemRequest request) {
        MenuItem menuItem = menuItemRepository.findById(request.menuItemId())
                .orElseThrow(() -> new ResourceNotFoundException("Item de cardápio não encontrado."));

        int quantityToAdd = request.quantity() == null ? 1 : request.quantity();
        if (quantityToAdd <= 0) {
            throw new BadRequestException("Quantidade deve ser maior que zero.");
        }

        CartItem item = cartItemRepository.findByUserIdAndMenuItemId(userId, request.menuItemId())
                .orElseGet(() -> CartItem.builder()
                        .user(userRepository.getReferenceById(userId))
                        .menuItem(menuItem)
                        .quantity(0)
                        .build());

        item.setQuantity(item.getQuantity() + quantityToAdd);
        cartItemRepository.save(item);

        return buildCartResponse(userId);
    }

    @Transactional
    public CartResponse updateQuantity(UUID userId, UUID menuItemId, int quantity) {
        if (quantity <= 0) {
            cartItemRepository.deleteByUserIdAndMenuItemId(userId, menuItemId);
        } else {
            CartItem item = cartItemRepository.findByUserIdAndMenuItemId(userId, menuItemId)
                    .orElseThrow(() -> new ResourceNotFoundException("Item não está no carrinho."));
            item.setQuantity(quantity);
            cartItemRepository.save(item);
        }
        return buildCartResponse(userId);
    }

    @Transactional
    public CartResponse removeItem(UUID userId, UUID menuItemId) {
        cartItemRepository.deleteByUserIdAndMenuItemId(userId, menuItemId);
        return buildCartResponse(userId);
    }

    @Transactional
    public void clear(UUID userId) {
        cartItemRepository.deleteByUserId(userId);
    }

    private CartResponse buildCartResponse(UUID userId) {
        var responses = cartItemRepository.findByUserIdOrderByAddedAtDesc(userId).stream()
                .map(this::toResponse)
                .toList();

        BigDecimal total = responses.stream()
                .map(CartItemResponse::subtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new CartResponse(responses, total);
    }

    private CartItemResponse toResponse(CartItem item) {
        MenuItemResponse menuItemResponse = MenuItemResponse.from(item.getMenuItem());
        BigDecimal subtotal = menuItemResponse.price().multiply(BigDecimal.valueOf(item.getQuantity()));
        return new CartItemResponse(item.getId(), menuItemResponse, item.getQuantity(), item.getAddedAt(), subtotal);
    }
}
