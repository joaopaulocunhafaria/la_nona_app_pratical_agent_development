-- Substitui o booleano menu_items.available por um status com mais estados.
-- available=true vira DISPONIVEL; available=false vira INDISPONIVEL. Os novos
-- estados intermediarios (FEITO_NA_HORA, VERIFICAR_DISPONIBILIDADE) so passam a
-- ser atribuiveis pela aplicacao apos esta migration.

ALTER TABLE menu_items ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'DISPONIVEL'
    CHECK (status IN (
        'DISPONIVEL', 'FEITO_NA_HORA', 'VERIFICAR_DISPONIBILIDADE', 'INDISPONIVEL'
    ));

UPDATE menu_items
SET status = CASE WHEN available THEN 'DISPONIVEL' ELSE 'INDISPONIVEL' END;

DROP INDEX IF EXISTS idx_menu_items_available;
ALTER TABLE menu_items DROP COLUMN available;

CREATE INDEX idx_menu_items_status ON menu_items (status);
