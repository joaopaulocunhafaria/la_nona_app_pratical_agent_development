package com.lanona.api.controller;

import com.lanona.api.dto.response.LoginMetricsResponse;
import com.lanona.api.dto.response.MenuViewMetricsResponse;
import com.lanona.api.dto.response.OnlineCountResponse;
import com.lanona.api.dto.response.SessionDurationResponse;
import com.lanona.api.dto.response.TopItemResponse;
import com.lanona.api.service.TelemetryAdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Consultas de telemetria expostas ao administrador. Protegido por hasRole
 * ADMIN (tambem coberto pela regra /api/admin/** do SecurityConfig).
 */
@RestController
@RequestMapping("/api/admin/telemetry")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class TelemetryAdminController {

    private static final Duration DEFAULT_PERIOD = Duration.ofDays(30);

    private final TelemetryAdminService adminService;

    @GetMapping("/online")
    public OnlineCountResponse online() {
        return adminService.online();
    }

    @GetMapping("/logins")
    public LoginMetricsResponse logins(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false, defaultValue = "day") String granularity) {
        Instant end = resolveTo(to);
        return adminService.logins(resolveFrom(from, end), end, granularity);
    }

    @GetMapping("/menu-views")
    public MenuViewMetricsResponse menuViews(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false, defaultValue = "day") String granularity) {
        Instant end = resolveTo(to);
        return adminService.menuViews(resolveFrom(from, end), end, granularity);
    }

    @GetMapping("/sessions")
    public SessionDurationResponse sessions(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false, defaultValue = "20") int limit) {
        Instant end = resolveTo(to);
        return adminService.sessionDurations(resolveFrom(from, end), end, limit);
    }

    @GetMapping("/top-items")
    public List<TopItemResponse> topItems(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false, defaultValue = "10") int limit) {
        Instant end = resolveTo(to);
        return adminService.topItems(resolveFrom(from, end), end, limit);
    }

    private Instant resolveTo(Instant to) {
        return to != null ? to : Instant.now();
    }

    private Instant resolveFrom(Instant from, Instant to) {
        return from != null ? from : to.minus(DEFAULT_PERIOD);
    }
}
