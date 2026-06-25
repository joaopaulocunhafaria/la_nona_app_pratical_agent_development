package com.lanona.api.service;

import com.lanona.api.dto.request.AddressRequest;
import com.lanona.api.dto.request.PhotoRequest;
import com.lanona.api.entity.User;
import com.lanona.api.exception.BadRequestException;
import com.lanona.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private S3StorageService storageService;

    @InjectMocks
    private UserService userService;

    private User user;
    private UUID userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        user = User.builder().id(userId).email("user@lanona.com").build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        lenient().when(userRepository.saveAndFlush(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void saveAddress_normalizesAndFormatsCep() {
        var request = new AddressRequest("01001000", "Praca da Se", "Centro", "10", "Sao Paulo", "sp", "");

        var response = userService.saveAddress(userId, request);

        assertThat(response.address().cep()).isEqualTo("01001-000");
        assertThat(response.address().estado()).isEqualTo("SP");
        assertThat(response.onboardingCompleted()).isTrue();
    }

    @Test
    void saveAddress_acceptsCepAlreadyFormattedWithDash() {
        var request = new AddressRequest("01001-000", "Praca da Se", "Centro", "10", "Sao Paulo", "SP", "");

        var response = userService.saveAddress(userId, request);

        assertThat(response.address().cep()).isEqualTo("01001-000");
    }

    @Test
    void saveAddress_rejectsCepWithWrongLength() {
        var request = new AddressRequest("123", "Praca da Se", "Centro", "10", "Sao Paulo", "SP", "");

        assertThatThrownBy(() -> userService.saveAddress(userId, request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("CEP inválido");
    }

    @Test
    void saveAddress_rejectsInvalidUf() {
        var request = new AddressRequest("01001000", "Praca da Se", "Centro", "10", "Sao Paulo", "XX", "");

        assertThatThrownBy(() -> userService.saveAddress(userId, request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("UF inválida");
    }

    @Test
    void saveAddress_rejectsInvalidNumero() {
        var request = new AddressRequest("01001000", "Praca da Se", "Centro", "número com espaço!", "Sao Paulo", "SP", "");

        assertThatThrownBy(() -> userService.saveAddress(userId, request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Número inválido");
    }

    @Test
    void saveAddress_rejectsTooShortStreet() {
        var request = new AddressRequest("01001000", "Aa", "Centro", "10", "Sao Paulo", "SP", "");

        assertThatThrownBy(() -> userService.saveAddress(userId, request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Rua");
    }

    @Test
    void updatePhoto_uploadsToBucketAndStoresOnlyUrl() {
        user.setPhoto("https://bucket/user-photos/old.jpg");
        when(storageService.uploadBase64("Zm9v", "image/jpeg", "user-photos"))
                .thenReturn("https://bucket/user-photos/new.jpg");

        var response = userService.updatePhoto(userId, new PhotoRequest("Zm9v", "image/jpeg"));

        assertThat(response.photo()).isEqualTo("https://bucket/user-photos/new.jpg");
        assertThat(user.getPhoto()).isEqualTo("https://bucket/user-photos/new.jpg");
        // a foto anterior e' removida do bucket.
        verify(storageService).delete("https://bucket/user-photos/old.jpg");
    }
}
