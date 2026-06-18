package com.lanona.api.controller;

import com.lanona.api.dto.request.AddCartItemRequest;
import com.lanona.api.dto.request.UpdateCartItemQuantityRequest;
import com.lanona.api.dto.response.CartResponse;
import com.lanona.api.security.UserPrincipal;
import com.lanona.api.service.CartService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    @GetMapping
    public CartResponse get(@AuthenticationPrincipal UserPrincipal principal) {
        return cartService.getCart(principal.getId());
    }

    @PostMapping("/items")
    public CartResponse addItem(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody AddCartItemRequest request) {
        return cartService.addItem(principal.getId(), request);
    }

    @PutMapping("/items/{menuItemId}")
    public CartResponse updateQuantity(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID menuItemId,
            @RequestBody UpdateCartItemQuantityRequest request) {
        return cartService.updateQuantity(principal.getId(), menuItemId, request.quantity());
    }

    @DeleteMapping("/items/{menuItemId}")
    public CartResponse removeItem(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID menuItemId) {
        return cartService.removeItem(principal.getId(), menuItemId);
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void clear(@AuthenticationPrincipal UserPrincipal principal) {
        cartService.clear(principal.getId());
    }
}
