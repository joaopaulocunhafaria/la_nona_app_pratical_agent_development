package com.lanona.api.controller;

import com.lanona.api.dto.response.ChatMessageResponse;
import com.lanona.api.dto.response.ChatThreadResponse;
import com.lanona.api.security.UserPrincipal;
import com.lanona.api.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @GetMapping("/threads")
    @PreAuthorize("hasRole('ADMIN')")
    public List<ChatThreadResponse> threads() {
        return chatService.getAllThreads();
    }

    @GetMapping("/threads/unread-count")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Integer> totalUnreadCount() {
        return Map.of("total", chatService.getTotalUnreadCountAdmin());
    }

    @GetMapping("/my-thread/unread-count")
    public Map<String, Integer> myUnreadCount(@AuthenticationPrincipal UserPrincipal principal) {
        return Map.of("count", chatService.getUnreadCountForUser(principal.getId()));
    }

    @GetMapping("/threads/{userId}/messages")
    public Page<ChatMessageResponse> messages(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID userId,
            Pageable pageable) {
        return chatService.getMessages(userId, principal.getId(), principal.isAdmin(), pageable);
    }

    @PutMapping("/threads/{userId}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markAsRead(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID userId,
            @RequestParam String as) {
        chatService.markAsRead(userId, principal.getId(), principal.isAdmin(), as);
    }
}
