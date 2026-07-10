package com.lanona.api.service;

import com.lanona.api.dto.response.LoginMetricsResponse;
import com.lanona.api.dto.response.MenuViewMetricsResponse;
import com.lanona.api.dto.response.OnlineCountResponse;
import com.lanona.api.dto.response.SessionDurationResponse;
import com.lanona.api.dto.response.TimeBucketResponse;
import com.lanona.api.dto.response.TopItemResponse;
import com.lanona.api.dto.response.UserDurationResponse;
import com.lanona.api.repository.ItemViewEventRepository;
import com.lanona.api.repository.LoginEventRepository;
import com.lanona.api.repository.MenuViewEventRepository;
import com.lanona.api.repository.TelemetrySessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/** Consultas agregadas de telemetria para o painel do administrador. */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TelemetryAdminService {

    /** Janela para considerar uma sessao "online agora". */
    private static final Duration ONLINE_WINDOW = Duration.ofSeconds(60);

    private final TelemetrySessionRepository sessionRepository;
    private final LoginEventRepository loginEventRepository;
    private final ItemViewEventRepository itemViewEventRepository;
    private final MenuViewEventRepository menuViewEventRepository;

    public OnlineCountResponse online() {
        Instant threshold = Instant.now().minus(ONLINE_WINDOW);
        long loggedIn = sessionRepository.countByEndedAtIsNullAndUserIsNotNullAndLastSeenAtAfter(threshold);
        long anonymous = sessionRepository.countByEndedAtIsNullAndUserIsNullAndLastSeenAtAfter(threshold);
        return new OnlineCountResponse(loggedIn, anonymous);
    }

    public LoginMetricsResponse logins(Instant from, Instant to, String granularity) {
        String bucket = normalizeGranularity(granularity);
        long total = loginEventRepository.countByCreatedAtBetween(from, to);
        long distinct = loginEventRepository.countDistinctUsers(from, to);
        List<TimeBucketResponse> series = loginEventRepository.loginsOverTime(bucket, from, to).stream()
                .map(TimeBucketResponse::from)
                .toList();
        return new LoginMetricsResponse(total, distinct, series);
    }

    public MenuViewMetricsResponse menuViews(Instant from, Instant to, String granularity) {
        String bucket = normalizeGranularity(granularity);
        long total = menuViewEventRepository.countByCreatedAtBetween(from, to);
        List<TimeBucketResponse> series = menuViewEventRepository.menuViewsOverTime(bucket, from, to).stream()
                .map(TimeBucketResponse::from)
                .toList();
        return new MenuViewMetricsResponse(total, series);
    }

    public SessionDurationResponse sessionDurations(Instant from, Instant to, int limit) {
        double avg = sessionRepository.averageActiveSeconds(from, to);
        long totalSessions = sessionRepository.countByStartedAtBetween(from, to);
        List<UserDurationResponse> ranking = sessionRepository
                .rankUserDurations(from, to, PageRequest.of(0, limit)).stream()
                .map(UserDurationResponse::from)
                .toList();
        return new SessionDurationResponse(avg, totalSessions, ranking);
    }

    public List<TopItemResponse> topItems(Instant from, Instant to, int limit) {
        return itemViewEventRepository.topViewedItems(from, to, PageRequest.of(0, limit)).stream()
                .map(TopItemResponse::from)
                .toList();
    }

    /** Apenas 'hour' ou 'day' sao aceitos pelo date_trunc; default 'day'. */
    private String normalizeGranularity(String granularity) {
        if (granularity != null && granularity.equalsIgnoreCase("hour")) {
            return "hour";
        }
        return "day";
    }
}
