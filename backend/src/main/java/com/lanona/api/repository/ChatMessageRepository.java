package com.lanona.api.repository;

import com.lanona.api.entity.ChatMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

    Page<ChatMessage> findByThreadUserIdOrderBySentAtDesc(UUID threadUserId, Pageable pageable);
}
