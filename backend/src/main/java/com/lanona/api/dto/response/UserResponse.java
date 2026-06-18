package com.lanona.api.dto.response;

import com.lanona.api.entity.Role;
import com.lanona.api.entity.User;

import java.time.Instant;
import java.util.UUID;

public record UserResponse(
        UUID id,
        String email,
        String name,
        String photo,
        String provider,
        String role,
        boolean isAdmin,
        boolean onboardingCompleted,
        AddressResponse address,
        Instant createdAt,
        Instant updatedAt
) {

    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getPhoto(),
                user.getProvider().name().toLowerCase(),
                user.getRole().name().toLowerCase(),
                user.getRole() == Role.ADMIN,
                user.isOnboardingCompleted(),
                AddressResponse.from(user),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}
