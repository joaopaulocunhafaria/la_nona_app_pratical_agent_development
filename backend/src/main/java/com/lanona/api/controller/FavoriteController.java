package com.lanona.api.controller;

import com.lanona.api.dto.response.MenuItemResponse;
import com.lanona.api.security.UserPrincipal;
import com.lanona.api.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/favorites")
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteService favoriteService;

    @GetMapping
    public List<MenuItemResponse> list(@AuthenticationPrincipal UserPrincipal principal) {
        return favoriteService.list(principal.getId());
    }

    @PostMapping("/{menuItemId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void add(@AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID menuItemId) {
        favoriteService.add(principal.getId(), menuItemId);
    }

    @DeleteMapping("/{menuItemId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID menuItemId) {
        favoriteService.remove(principal.getId(), menuItemId);
    }
}
