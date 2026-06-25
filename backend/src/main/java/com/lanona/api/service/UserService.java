package com.lanona.api.service;

import com.lanona.api.dto.request.AddressRequest;
import com.lanona.api.dto.request.PhotoRequest;
import com.lanona.api.dto.request.RoleUpdateRequest;
import com.lanona.api.dto.response.UserResponse;
import com.lanona.api.entity.Role;
import com.lanona.api.entity.User;
import com.lanona.api.exception.BadRequestException;
import com.lanona.api.exception.ResourceNotFoundException;
import com.lanona.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class UserService {

    // Mesmas regras de validacao de endereco do AddressFormService do app Flutter.
    private static final Set<String> VALID_UFS = Set.of(
            "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG",
            "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"
    );
    private static final Pattern CEP_PATTERN = Pattern.compile("\\d{8}");
    private static final Pattern NUMERO_PATTERN = Pattern.compile("^[0-9A-Za-z/-]{1,10}$");
    private static final int COMPLEMENTO_MAX_LENGTH = 60;

    private static final String PHOTO_DIRECTORY = "user-photos";

    private final UserRepository userRepository;
    private final S3StorageService storageService;

    public UserResponse getById(UUID id) {
        return UserResponse.from(findById(id));
    }

    public List<UserResponse> search(String search) {
        List<User> users = (search == null || search.isBlank())
                ? userRepository.findAllByOrderByNameAsc()
                : userRepository.findByNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByNameAsc(search, search);

        return users.stream().map(UserResponse::from).toList();
    }

    @Transactional
    public UserResponse saveAddress(UUID userId, AddressRequest request) {
        User user = findById(userId);

        String cep = normalizeCep(request.cep());
        if (cep.isEmpty()) {
            throw new BadRequestException("CEP obrigatório.");
        }
        if (!CEP_PATTERN.matcher(cep).matches()) {
            throw new BadRequestException("CEP inválido. Use 8 dígitos.");
        }

        String rua = requiredMin(request.rua(), 3, "Rua");
        String bairro = requiredMin(request.bairro(), 2, "Bairro");
        String cidade = requiredMin(request.cidade(), 2, "Cidade");

        String numero = trimOrEmpty(request.numero());
        if (numero.isEmpty()) {
            throw new BadRequestException("Número: campo obrigatório.");
        }
        if (!NUMERO_PATTERN.matcher(numero).matches()) {
            throw new BadRequestException("Número inválido.");
        }

        String estado = trimOrEmpty(request.estado()).toUpperCase();
        if (estado.isEmpty()) {
            throw new BadRequestException("UF: campo obrigatório.");
        }
        if (!VALID_UFS.contains(estado)) {
            throw new BadRequestException("UF inválida.");
        }

        String complemento = trimOrEmpty(request.complemento());
        if (complemento.length() > COMPLEMENTO_MAX_LENGTH) {
            throw new BadRequestException("Complemento: máximo de " + COMPLEMENTO_MAX_LENGTH + " caracteres.");
        }

        user.setAddressCep(formatCep(cep));
        user.setAddressRua(rua);
        user.setAddressBairro(bairro);
        user.setAddressNumero(numero);
        user.setAddressCidade(cidade);
        user.setAddressEstado(estado);
        user.setAddressComplemento(complemento);
        user.setOnboardingCompleted(true);

        return UserResponse.from(userRepository.saveAndFlush(user));
    }

    @Transactional
    public UserResponse updatePhoto(UUID userId, PhotoRequest request) {
        User user = findById(userId);

        String previousPhoto = user.getPhoto();
        // Envia a imagem ao bucket e guarda somente a URL publica.
        String photoUrl = storageService.uploadBase64(request.imageBase64(), request.contentType(), PHOTO_DIRECTORY);
        user.setPhoto(photoUrl);

        UserResponse response = UserResponse.from(userRepository.saveAndFlush(user));

        // Remove a foto anterior do bucket (no-op para fotos externas, ex.: Google).
        storageService.delete(previousPhoto);

        return response;
    }

    @Transactional
    public UserResponse updateRole(UUID id, RoleUpdateRequest request) {
        User user = findById(id);

        Role role;
        try {
            role = Role.valueOf(request.role().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Cargo inválido. Use: cliente, entregador ou admin.");
        }

        user.setRole(role);
        return UserResponse.from(userRepository.saveAndFlush(user));
    }

    private User findById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado."));
    }

    private String normalizeCep(String cep) {
        return trimOrEmpty(cep).replaceAll("\\D", "");
    }

    private String formatCep(String normalizedCep) {
        return normalizedCep.substring(0, 5) + "-" + normalizedCep.substring(5);
    }

    private String requiredMin(String value, int min, String fieldLabel) {
        String trimmed = trimOrEmpty(value);
        if (trimmed.isEmpty()) {
            throw new BadRequestException(fieldLabel + ": campo obrigatório.");
        }
        if (trimmed.length() < min) {
            throw new BadRequestException(fieldLabel + ": mínimo de " + min + " caracteres.");
        }
        return trimmed;
    }

    private String trimOrEmpty(String value) {
        return value == null ? "" : value.trim();
    }
}
