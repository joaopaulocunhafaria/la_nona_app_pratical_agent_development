package com.lanona.api.dto.response;

import com.lanona.api.entity.ChatThread;

import java.time.Instant;
import java.util.UUID;

public record ChatThreadResponse(
        UUID userId,
        String userName,
        String lastMessage,
        Instant updatedAt,
        int adminUnreadCount,
        int userUnreadCount
) {

    public static ChatThreadResponse from(ChatThread thread) {
        return new ChatThreadResponse(
                thread.getUserId(),
                thread.getUser().getName(),
                thread.getLastMessage(),
                thread.getUpdatedAt(),
                thread.getAdminUnreadCount(),
                thread.getUserUnreadCount()
        );
    }
}
