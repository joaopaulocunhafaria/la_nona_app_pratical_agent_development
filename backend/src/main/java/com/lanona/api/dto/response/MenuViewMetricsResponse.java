package com.lanona.api.dto.response;

import java.util.List;

/** Metricas de acesso ao cardapio num periodo: total e serie temporal. */
public record MenuViewMetricsResponse(
        long total,
        List<TimeBucketResponse> series
) {
}
