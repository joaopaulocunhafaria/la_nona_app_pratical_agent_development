package com.lanona.api.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.lanona.api.dto.request.GoogleLoginRequest;
import com.lanona.api.dto.request.LoginRequest;
import com.lanona.api.dto.request.RefreshTokenRequest;
import com.lanona.api.dto.request.RegisterRequest;
import com.lanona.api.dto.response.AuthResponse;
import com.lanona.api.dto.response.UserResponse;
import com.lanona.api.entity.AuthProvider;
import com.lanona.api.entity.RefreshToken;
import com.lanona.api.entity.Role;
import com.lanona.api.entity.User;
import com.lanona.api.exception.ConflictException;
import com.lanona.api.exception.UnauthorizedException;
import com.lanona.api.repository.RefreshTokenRepository;
import com.lanona.api.repository.UserRepository;
import com.lanona.api.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final GoogleTokenVerifierService googleTokenVerifierService;
    private final AuthenticationManager authenticationManager;

    @Value("${app.jwt.refresh-token-expiration-ms}")
    private long refreshTokenExpirationMs;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase();

        if (userRepository.existsByEmail(email)) {
            throw new ConflictException("Email já está cadastrado. Tente fazer login.");
        }

        User user = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(request.password()))
                .name(request.name() == null ? "" : request.name().trim())
                .provider(AuthProvider.LOCAL)
                .role(Role.CLIENTE)
                .build();

        // saveAndFlush: createdAt/updatedAt sao gerados pelo Hibernate so' no
        // flush; save() sozinho deixaria esses campos null na resposta abaixo.
        user = userRepository.saveAndFlush(user);
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Usuário não encontrado. Crie uma conta primeiro."));

        if (user.getProvider() != AuthProvider.LOCAL) {
            throw new UnauthorizedException("Esta conta usa login com Google.");
        }

        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, request.password()));
        } catch (BadCredentialsException e) {
            throw new UnauthorizedException("Senha incorreta.");
        } catch (DisabledException | LockedException e) {
            throw new UnauthorizedException("Usuário foi desabilitado.");
        }

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        GoogleIdToken.Payload payload = googleTokenVerifierService.verify(request.idToken());

        String email = payload.getEmail().toLowerCase();
        String name = (String) payload.get("name");
        String picture = (String) payload.get("picture");

        User user = userRepository.findByEmail(email).orElseGet(() -> User.builder()
                .email(email)
                .provider(AuthProvider.GOOGLE)
                .role(Role.CLIENTE)
                .build());

        if (name != null) {
            user.setName(name);
        }
        if (picture != null) {
            user.setPhoto(picture);
        }
        user.setProvider(AuthProvider.GOOGLE);

        // saveAndFlush: createdAt/updatedAt sao gerados pelo Hibernate so' no
        // flush; save() sozinho deixaria esses campos null na resposta abaixo.
        user = userRepository.saveAndFlush(user);
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse refresh(RefreshTokenRequest request) {
        RefreshToken stored = refreshTokenRepository.findByTokenHash(hashToken(request.refreshToken()))
                .orElseThrow(() -> new UnauthorizedException("Refresh token inválido."));

        if (stored.isRevoked() || stored.getExpiresAt().isBefore(Instant.now())) {
            throw new UnauthorizedException("Refresh token expirado ou revogado.");
        }

        stored.setRevoked(true);
        refreshTokenRepository.save(stored);

        return buildAuthResponse(stored.getUser());
    }

    @Transactional
    public void logout(RefreshTokenRequest request) {
        refreshTokenRepository.findByTokenHash(hashToken(request.refreshToken()))
                .ifPresent(token -> {
                    token.setRevoked(true);
                    refreshTokenRepository.save(token);
                });
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String rawRefreshToken = generateRawRefreshToken();

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .tokenHash(hashToken(rawRefreshToken))
                .expiresAt(Instant.now().plusMillis(refreshTokenExpirationMs))
                .revoked(false)
                .build();
        refreshTokenRepository.save(refreshToken);

        return new AuthResponse(accessToken, rawRefreshToken, UserResponse.from(user));
    }

    private String generateRawRefreshToken() {
        byte[] bytes = new byte[64];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 não disponível", e);
        }
    }
}
