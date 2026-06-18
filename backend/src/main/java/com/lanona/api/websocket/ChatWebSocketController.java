package com.lanona.api.websocket;

import com.lanona.api.dto.request.SendChatMessageRequest;
import com.lanona.api.dto.response.ChatMessageResponse;
import com.lanona.api.security.UserPrincipal;
import com.lanona.api.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.UUID;

/**
 * Recebimento/envio de mensagens do chat de suporte via STOMP.
 * Autenticacao do Principal e' feita no handshake (WebSocketConfig).
 * Ver SPRINGBOOT.md secao 7.
 */
@Controller
@RequiredArgsConstructor
public class ChatWebSocketController {

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/chat.{userId}.send")
    public void send(
            @DestinationVariable UUID userId,
            @Payload SendChatMessageRequest payload,
            Principal principal) {

        UserPrincipal sender = (UserPrincipal) ((UsernamePasswordAuthenticationToken) principal).getPrincipal();

        ChatMessageResponse message = chatService.sendMessage(userId, sender.getId(), sender.isAdmin(), payload.text());

        messagingTemplate.convertAndSend("/topic/chat." + userId, message);
        messagingTemplate.convertAndSend("/topic/chat.admin.threads", chatService.getThreadSummary(userId));
    }
}
