package com.lanona.api.service;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.lanona.api.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class S3StorageServiceTest {

    private static final String BASE_URL = "https://s3.sa-east-1.amazonaws.com";
    private static final String BUCKET = "la-nona-images";

    @Mock
    private AmazonS3 s3;

    private S3StorageService storageService;

    @BeforeEach
    void setUp() {
        storageService = new S3StorageService(s3);
        ReflectionTestUtils.setField(storageService, "url", BASE_URL);
        ReflectionTestUtils.setField(storageService, "bucket", BUCKET);
    }

    @Test
    void uploadBase64_uploadsPublicObjectAndReturnsDeterministicUrl() {
        String base64 = Base64.getEncoder().encodeToString("foo".getBytes());

        String url = storageService.uploadBase64(base64, "image/png", "menu-items");

        assertThat(url).startsWith(BASE_URL + "/" + BUCKET + "/menu-items/");
        assertThat(url).endsWith(".png");

        ArgumentCaptor<PutObjectRequest> captor = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(s3).putObject(captor.capture());
        PutObjectRequest request = captor.getValue();
        assertThat(request.getBucketName()).isEqualTo(BUCKET);
        assertThat(request.getCannedAcl()).isEqualTo(CannedAccessControlList.PublicRead);
        assertThat(request.getMetadata().getContentType()).isEqualTo("image/png");
        assertThat(request.getMetadata().getContentLength()).isEqualTo(3);
    }

    @Test
    void uploadBase64_acceptsDataUriPrefix() {
        String base64 = Base64.getEncoder().encodeToString("bar".getBytes());

        String url = storageService.uploadBase64("data:image/jpeg;base64," + base64, "image/jpeg", "menu-items");

        assertThat(url).endsWith(".jpg");
        verify(s3).putObject(org.mockito.ArgumentMatchers.any(PutObjectRequest.class));
    }

    @Test
    void uploadBase64_rejectsBlankContent() {
        assertThatThrownBy(() -> storageService.uploadBase64("  ", "image/png", "menu-items"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Imagem inválida");
        verify(s3, never()).putObject(org.mockito.ArgumentMatchers.any(PutObjectRequest.class));
    }

    @Test
    void uploadBase64_rejectsMalformedBase64() {
        assertThatThrownBy(() -> storageService.uploadBase64("!!!not base64!!!", "image/png", "menu-items"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("base64");
    }

    @Test
    void delete_removesObjectForManagedUrl() {
        String url = BASE_URL + "/" + BUCKET + "/menu-items/123-abc.png";

        boolean removed = storageService.delete(url);

        assertThat(removed).isTrue();
        verify(s3).deleteObject(BUCKET, "menu-items/123-abc.png");
    }

    @Test
    void delete_ignoresExternalUrl() {
        boolean removed = storageService.delete("https://lh3.googleusercontent.com/a/foto.jpg");

        assertThat(removed).isFalse();
        verify(s3, never()).deleteObject(org.mockito.ArgumentMatchers.anyString(), org.mockito.ArgumentMatchers.anyString());
    }

    @Test
    void delete_ignoresNull() {
        assertThat(storageService.delete(null)).isFalse();
    }

    @Test
    void isManagedUrl_distinguishesOwnedFromExternal() {
        assertThat(storageService.isManagedUrl(BASE_URL + "/" + BUCKET + "/x.png")).isTrue();
        assertThat(storageService.isManagedUrl("https://example.com/x.png")).isFalse();
        assertThat(storageService.isManagedUrl(null)).isFalse();
    }
}
