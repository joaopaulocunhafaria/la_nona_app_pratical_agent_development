-- Acessos a aba de cardapio (/menu). Registrado a cada navegacao para a lista
-- do cardapio (logado ou anonimo), SEM deduplicacao: cada acesso conta, mesmo
-- que o usuario va para a home e volte para o menu varias vezes.
CREATE TABLE menu_view_events (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID REFERENCES users (id) ON DELETE SET NULL,
    anonymous_id  VARCHAR(64),
    platform      VARCHAR(16),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_menu_view_events_created_at ON menu_view_events (created_at);
