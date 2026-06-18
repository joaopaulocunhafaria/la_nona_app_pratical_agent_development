package com.lanona.api.service;

import com.lanona.api.dto.response.ChatMessageResponse;
import com.lanona.api.dto.response.ChatThreadResponse;
import com.lanona.api.entity.ChatMessage;
import com.lanona.api.entity.ChatThread;
import com.lanona.api.entity.User;
import com.lanona.api.exception.ForbiddenException;
import com.lanona.api.exception.ResourceNotFoundException;
import com.lanona.api.repository.ChatMessageRepository;
import com.lanona.api.repository.ChatThreadRepository;
import com.lanona.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Regras de negocio do chat de suporte. O transporte em tempo real
 * (WebSocket/STOMP) fica no controller dedicado (websocket/ChatWebSocketController),
 * que chama estes mesmos metodos e depois faz o broadcast.
 */
@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatThreadRepository chatThreadRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<ChatThreadResponse> getAllThreads() {
        return chatThreadRepository.findAllByOrderByUpdatedAtDesc().stream()
                .map(ChatThreadResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public int getTotalUnreadCountAdmin() {
        return chatThreadRepository.sumAdminUnreadCount();
    }

    @Transactional(readOnly = true)
    public int getUnreadCountForUser(UUID userId) {
        return chatThreadRepository.findById(userId)
                .map(ChatThread::getUserUnreadCount)
                .orElse(0);
    }

    @Transactional(readOnly = true)
    public ChatThreadResponse getThreadSummary(UUID threadUserId) {
        return chatThreadRepository.findById(threadUserId)
                .map(ChatThreadResponse::from)
                .orElseThrow(() -> new ResourceNotFoundException("Conversa não encontrada."));
    }

    @Transactional(readOnly = true)
    public Page<ChatMessageResponse> getMessages(
            UUID threadUserId, UUID requesterId, boolean requesterIsAdmin, Pageable pageable) {
        assertAccess(threadUserId, requesterId, requesterIsAdmin);
        return chatMessageRepository.findByThreadUserIdOrderBySentAtDesc(threadUserId, pageable)
                .map(ChatMessageResponse::from);
    }

    @Transactional
    public ChatMessageResponse sendMessage(UUID threadUserId, UUID senderId, boolean senderIsAdmin, String text) {
        assertAccess(threadUserId, senderId, senderIsAdmin);

        ChatThread thread = chatThreadRepository.findById(threadUserId).orElse(null);
        if (thread == null) {
            // saveAndFlush: a thread precisa existir de fato no banco antes da
            // ChatMessage (FK not-null) ser inserida referenciando-a — um save()
            // sem flush deixa a thread transiente e a inserção da mensagem falha.
            User threadOwner = userRepository.findById(threadUserId)
                    .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado."));
            thread = chatThreadRepository.saveAndFlush(ChatThread.builder()
                    .user(threadOwner)
                    .updatedAt(Instant.now())
                    .build());
        }

        ChatMessage message = ChatMessage.builder()
                .thread(thread)
                .sender(userRepository.getReferenceById(senderId))
                .text(text)
                .admin(senderIsAdmin)
                .build();
        chatMessageRepository.saveAndFlush(message);

        thread.setLastMessage(text);
        thread.setUpdatedAt(Instant.now());
        if (senderIsAdmin) {
            thread.setUserUnreadCount(thread.getUserUnreadCount() + 1);
        } else {
            thread.setAdminUnreadCount(thread.getAdminUnreadCount() + 1);
        }
        chatThreadRepository.save(thread);

        return ChatMessageResponse.from(message);
    }

    @Transactional
    public void markAsRead(UUID threadUserId, UUID requesterId, boolean requesterIsAdmin, String as) {
        boolean asAdmin = "admin".equalsIgnoreCase(as);

        if (asAdmin && !requesterIsAdmin) {
            throw new ForbiddenException("Apenas administradores podem marcar como lido nesse modo.");
        }
        if (!asAdmin && !requesterId.equals(threadUserId)) {
            throw new ForbiddenException("Você só pode marcar como lida a sua própria conversa.");
        }

        ChatThread thread = chatThreadRepository.findById(threadUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Conversa não encontrada."));

        if (asAdmin) {
            thread.setAdminUnreadCount(0);
        } else {
            thread.setUserUnreadCount(0);
        }
        chatThreadRepository.save(thread);
    }

    private void assertAccess(UUID threadUserId, UUID requesterId, boolean requesterIsAdmin) {
        if (!requesterIsAdmin && !requesterId.equals(threadUserId)) {
            throw new ForbiddenException("Você não tem acesso a essa conversa.");
        }
    }
}
