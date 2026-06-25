package com.lanona.api.service;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3URI;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.lanona.api.exception.BadRequestException;
import com.lanona.api.exception.StorageException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.net.URI;
import java.text.Normalizer;
import java.util.Base64;
import java.util.Locale;

/**
 * Unico ponto de acesso ao Amazon S3. Nenhuma outra classe deve falar
 * diretamente com o {@link AmazonS3}: servicos de dominio (cardapio, usuario)
 * enviam a imagem por aqui e guardam apenas a URL publica retornada.
 *
 * <p>O bucket e a URL base vem da config ({@code amazon.s3.*}); para usar um
 * bucket real basta ajustar as variaveis de ambiente correspondentes.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class S3StorageService {

    private final AmazonS3 s3;

    @Value("${amazon.s3.url}")
    private String url;

    @Value("${amazon.s3.bucketName}")
    private String bucket;

    /**
     * Envia uma imagem codificada em base64 para o bucket e devolve a URL
     * publica do objeto. O {@code base64} pode vir puro ou como data URI
     * ({@code data:image/png;base64,...}) — o prefixo e' descartado.
     *
     * @param directory subdiretorio logico (key prefix) onde gravar, ex.: "menu-items"
     */
    public String uploadBase64(String base64, String contentType, String directory) {
        if (base64 == null || base64.isBlank()) {
            throw new BadRequestException("Imagem inválida: conteúdo vazio.");
        }
        byte[] bytes = decode(base64);

        String key = buildKey(directory, fileExtension(contentType));
        ObjectMetadata metadata = new ObjectMetadata();
        metadata.setContentType(contentType);
        metadata.setContentLength(bytes.length);
        // Imagens sao imutaveis (nome unico por upload): cacheia agressivamente.
        metadata.setCacheControl("public, max-age=31536000");

        try (InputStream input = new ByteArrayInputStream(bytes)) {
            s3.putObject(new PutObjectRequest(bucket, key, input, metadata)
                    .withCannedAcl(CannedAccessControlList.PublicRead));
        } catch (Exception e) {
            log.error("Falha ao enviar imagem para o S3 (bucket={}, key={})", bucket, key, e);
            throw new StorageException("Não foi possível salvar a imagem. Tente novamente.");
        }

        return publicUrl(key);
    }

    /**
     * Remove do bucket o objeto referenciado por {@code fileUrl}. Ignora URLs
     * que nao pertencem a este bucket (ex.: foto original do Google) e nunca
     * propaga falha — limpeza de arquivo orfao nao deve quebrar a operacao
     * principal. Retorna {@code true} se algo foi removido.
     */
    public boolean delete(String fileUrl) {
        if (!isManagedUrl(fileUrl)) {
            return false;
        }
        try {
            AmazonS3URI s3URI = new AmazonS3URI(new URI(fileUrl));
            s3.deleteObject(s3URI.getBucket(), s3URI.getKey());
            return true;
        } catch (Exception e) {
            log.warn("Falha ao remover imagem do S3 (url={})", fileUrl, e);
            return false;
        }
    }

    /**
     * {@code true} se a URL aponta para um objeto deste bucket (e portanto foi
     * gerada por este servico), e nao para um host externo.
     */
    public boolean isManagedUrl(String fileUrl) {
        return fileUrl != null && fileUrl.startsWith(bucketBaseUrl());
    }

    private byte[] decode(String base64) {
        String raw = base64;
        int comma = raw.indexOf(',');
        if (raw.startsWith("data:") && comma > 0) {
            raw = raw.substring(comma + 1);
        }
        try {
            return Base64.getDecoder().decode(raw);
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Imagem inválida: base64 malformado.");
        }
    }

    private String buildKey(String directory, String extension) {
        String name = System.currentTimeMillis() + "-" + slug(java.util.UUID.randomUUID().toString()) + extension;
        return (directory == null || directory.isBlank()) ? name : slug(directory) + "/" + name;
    }

    private String fileExtension(String contentType) {
        if (contentType == null) {
            return "";
        }
        return switch (contentType.toLowerCase(Locale.ROOT)) {
            case "image/jpeg", "image/jpg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "image/gif" -> ".gif";
            default -> "";
        };
    }

    private String publicUrl(String key) {
        return bucketBaseUrl() + "/" + key;
    }

    private String bucketBaseUrl() {
        String base = url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
        return base + "/" + bucket;
    }

    /** Slug sem acentos/espacos/pontuacao — seguro para key do S3 e para URL. */
    private String slug(String value) {
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "");
        return normalized.toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9./-]", "-")
                .replaceAll("-{2,}", "-")
                .replaceAll("(^-|-$)", "");
    }
}
