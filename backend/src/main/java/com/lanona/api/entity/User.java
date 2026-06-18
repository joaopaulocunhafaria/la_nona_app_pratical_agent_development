package com.lanona.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash")
    private String passwordHash;

    @Builder.Default
    @Column(nullable = false)
    private String name = "";

    private String photo;

    @Builder.Default
    @Convert(converter = AuthProviderConverter.class)
    @Column(nullable = false)
    private AuthProvider provider = AuthProvider.LOCAL;

    @Builder.Default
    @Convert(converter = RoleConverter.class)
    @Column(nullable = false)
    private Role role = Role.CLIENTE;

    @Builder.Default
    @Column(name = "onboarding_completed", nullable = false)
    private boolean onboardingCompleted = false;

    @Column(name = "address_cep")
    private String addressCep;

    @Column(name = "address_rua")
    private String addressRua;

    @Column(name = "address_bairro")
    private String addressBairro;

    @Column(name = "address_numero")
    private String addressNumero;

    @Column(name = "address_cidade")
    private String addressCidade;

    @Column(name = "address_estado")
    private String addressEstado;

    @Column(name = "address_complemento")
    private String addressComplemento;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
