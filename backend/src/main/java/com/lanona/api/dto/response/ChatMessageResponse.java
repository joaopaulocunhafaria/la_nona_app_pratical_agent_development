package com.lanona.api.dto.response;

import com.lanona.api.entity.ChatMessage;

import java.time.Instant;
import java.util.UUID;

public record ChatMessageResponse(
        UUID id,
        UUID senderId,
        String text,
        boolean isAdmin,
        Instant sentAt
) {

    public static ChatMessageResponse from(ChatMessage message) {
        return new ChatMessageResponse(
                message.getId(),
                message.getSender().getId(),
                message.getText(),
                message.isAdmin(),
                message.getSentAt()
        );
    }
}
