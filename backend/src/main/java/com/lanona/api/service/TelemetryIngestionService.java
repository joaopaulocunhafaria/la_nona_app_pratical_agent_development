package com.lanona.api.service;

import com.lanona.api.entity.ItemViewEvent;
import com.lanona.api.entity.LoginEvent;
import com.lanona.api.entity.MenuViewEvent;
import com.lanona.api.entity.Platform;
import com.lanona.api.entity.TelemetrySession;
import com.lanona.api.repository.ItemViewEventRepository;
import com.lanona.api.repository.LoginEventRepository;
import com.lanona.api.repository.MenuItemRepository;
import com.lanona.api.repository.MenuViewEventRepository;
import com.lanona.api.repository.TelemetrySessionRepository;
import com.lanona.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Coleta (ingestao) de eventos de telemetria enviados pelos clientes web e
 * mobile. As operacoes sao best-effort: a sessao pode ja ter sido encerrada ou
 * nao existir (ex.: limpeza de cache no cliente), e nesses casos ignoramos sem
 * quebrar o fluxo do usuario.
 */
@Service
@RequiredArgsConstructor
public class TelemetryIngestionService {

    private final TelemetrySessionRepository sessionRepository;
    private final LoginEventRepository loginEventRepository;
    private final ItemViewEventRepository itemViewEventRepository;
    private final MenuViewEventRepository menuViewEventRepository;
    private final UserRepository userRepository;
    private final MenuItemRepository menuItemRepository;

    @Transactional
    public UUID startSession(String anonymousId, Platform platform, UUID userId) {
        Instant now = Instant.now();
        TelemetrySession session = TelemetrySession.builder()
                .user(userId == null ? null : userRepository.getReferenceById(userId))
                .anonymousId(anonymousId)
                .platform(platform)
                .startedAt(now)
                .lastSeenAt(now)
                .activeSeconds(0)
                .build();
        return sessionRepository.save(session).getId();
    }

    @Transactional
    public void heartbeat(UUID sessionId, Long activeSeconds, UUID userId) {
        sessionRepository.findById(sessionId).ifPresent(session -> {
            session.setLastSeenAt(Instant.now());
            applyActiveSeconds(session, activeSeconds);
            // Associa o usuario caso a sessao tenha comecado anonima e o login
            // tenha ocorrido depois (heartbeats passam a vir com o JWT).
            if (session.getUser() == null && userId != null) {
                session.setUser(userRepository.getReferenceById(userId));
            }
            sessionRepository.save(session);
        });
    }

    @Transactional
    public void endSession(UUID sessionId, Long activeSeconds) {
        sessionRepository.findById(sessionId).ifPresent(session -> {
            Instant now = Instant.now();
            session.setLastSeenAt(now);
            session.setEndedAt(now);
            applyActiveSeconds(session, activeSeconds);
            sessionRepository.save(session);
        });
    }

    @Transactional
    public void recordItemView(UUID menuItemId, String anonymousId, Platform platform, UUID userId) {
        if (!menuItemRepository.existsById(menuItemId)) {
            return;
        }
        ItemViewEvent event = ItemViewEvent.builder()
                .menuItem(menuItemRepository.getReferenceById(menuItemId))
                .user(userId == null ? null : userRepository.getReferenceById(userId))
                .anonymousId(anonymousId)
                .platform(platform)
                .build();
        itemViewEventRepository.save(event);
    }

    @Transactional
    public void recordMenuView(String anonymousId, Platform platform, UUID userId) {
        MenuViewEvent event = MenuViewEvent.builder()
                .user(userId == null ? null : userRepository.getReferenceById(userId))
                .anonymousId(anonymousId)
                .platform(platform)
                .build();
        menuViewEventRepository.save(event);
    }

    @Transactional
    public void recordLogin(UUID userId, Platform platform) {
        LoginEvent event = LoginEvent.builder()
                .user(userRepository.getReferenceById(userId))
                .platform(platform)
                .build();
        loginEventRepository.save(event);
    }

    /** Atualiza o tempo ativo, nunca regredindo (heartbeats fora de ordem). */
    private void applyActiveSeconds(TelemetrySession session, Long activeSeconds) {
        if (activeSeconds != null && activeSeconds > session.getActiveSeconds()) {
            session.setActiveSeconds(activeSeconds);
        }
    }
}
