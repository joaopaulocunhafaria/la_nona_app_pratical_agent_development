-- As imagens passam a ser armazenadas no bucket (S3): a coluna guarda agora a
-- URL publica do objeto, e nao mais o binario/base64. Renomeada para refletir
-- a nova semantica. Linhas antigas (data URI base64) continuam validas como
-- valor de imagem ate' serem regravadas.
ALTER TABLE menu_item_images RENAME COLUMN image_data TO image_url;
