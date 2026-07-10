package com.lanona.api.controller;

import com.lanona.api.dto.request.HeartbeatRequest;
import com.lanona.api.dto.request.ItemViewRequest;
import com.lanona.api.dto.request.MenuViewRequest;
import com.lanona.api.dto.request.SessionStartRequest;
import com.lanona.api.dto.response.SessionStartResponse;
import com.lanona.api.entity.Platform;
import com.lanona.api.security.UserPrincipal;
import com.lanona.api.service.TelemetryIngestionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Endpoints publicos de coleta de telemetria. Aceitam acesso anonimo (sem JWT);
 * quando um JWT valido esta presente, o usuario e' associado automaticamente
 * via @AuthenticationPrincipal.
 */
@RestController
@RequestMapping("/api/telemetry")
@RequiredArgsConstructor
public class TelemetryController {

    private final TelemetryIngestionService ingestionService;

    @PostMapping("/sessions")
    @ResponseStatus(HttpStatus.CREATED)
    public SessionStartResponse startSession(
            @Valid @RequestBody SessionStartRequest request,
            @RequestHeader(value = "X-Client-Platform", required = false) String platformHeader,
            @AuthenticationPrincipal UserPrincipal principal) {
        Platform platform = resolvePlatform(request.platform(), platformHeader);
        UUID sessionId = ingestionService.startSession(request.anonymousId(), platform, userId(principal));
        return new SessionStartResponse(sessionId);
    }

    @PostMapping("/sessions/{id}/heartbeat")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void heartbeat(
            @PathVariable UUID id,
            @RequestBody(required = false) HeartbeatRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long activeSeconds = request == null ? null : request.activeSeconds();
        ingestionService.heartbeat(id, activeSeconds, userId(principal));
    }

    @PostMapping("/sessions/{id}/end")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void endSession(
            @PathVariable UUID id,
            @RequestBody(required = false) HeartbeatRequest request) {
        Long activeSeconds = request == null ? null : request.activeSeconds();
        ingestionService.endSession(id, activeSeconds);
    }

    @PostMapping("/menu-views")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void recordMenuView(
            @RequestBody(required = false) MenuViewRequest request,
            @RequestHeader(value = "X-Client-Platform", required = false) String platformHeader,
            @AuthenticationPrincipal UserPrincipal principal) {
        String anonymousId = request == null ? null : request.anonymousId();
        String bodyPlatform = request == null ? null : request.platform();
        Platform platform = resolvePlatform(bodyPlatform, platformHeader);
        ingestionService.recordMenuView(anonymousId, platform, userId(principal));
    }

    @PostMapping("/item-views")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void recordItemView(
            @Valid @RequestBody ItemViewRequest request,
            @RequestHeader(value = "X-Client-Platform", required = false) String platformHeader,
            @AuthenticationPrincipal UserPrincipal principal) {
        Platform platform = resolvePlatform(request.platform(), platformHeader);
        ingestionService.recordItemView(request.menuItemId(), request.anonymousId(), platform, userId(principal));
    }

    private UUID userId(UserPrincipal principal) {
        return principal == null ? null : principal.getId();
    }

    private Platform resolvePlatform(String fromBody, String fromHeader) {
        return Platform.fromNullable(fromBody != null ? fromBody : fromHeader);
    }
}
