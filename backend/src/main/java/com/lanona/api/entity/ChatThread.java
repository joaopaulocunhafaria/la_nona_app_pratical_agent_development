package com.lanona.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * A thread e identificada pelo id do cliente (o mesmo padrao do Firestore
 * original: doc id de 'chats' = uid do usuario). userId e' ao mesmo tempo
 * chave primaria e FK para users.id (@MapsId).
 */
@Entity
@Table(name = "chat_threads")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatThread {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "last_message", columnDefinition = "text")
    private String lastMessage;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Builder.Default
    @Column(name = "admin_unread_count", nullable = false)
    private int adminUnreadCount = 0;

    @Builder.Default
    @Column(name = "user_unread_count", nullable = false)
    private int userUnreadCount = 0;
}
