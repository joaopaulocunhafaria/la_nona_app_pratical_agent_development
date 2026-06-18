package com.lanona.api.config;

import com.lanona.api.entity.Role;
import com.lanona.api.security.JwtTokenProvider;
import com.lanona.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.lang.NonNull;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.UUID;

/**
 * Config do chat de suporte em tempo real (STOMP sobre SockJS). Ver
 * SPRINGBOOT.md secao 7.
 */
@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").setAllowedOriginPatterns("*").withSockJS();
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(@NonNull Message<?> message, @NonNull MessageChannel channel) {
                StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    accessor.setUser(authenticateOrThrow(accessor));
                }

                return message;
            }
        });
    }

    private UsernamePasswordAuthenticationToken authenticateOrThrow(StompHeaderAccessor accessor) {
        String header = accessor.getFirstNativeHeader("Authorization");

        if (header == null || !header.startsWith(BEARER_PREFIX)) {
            throw new MessagingException("Header Authorization ausente no CONNECT do STOMP.");
        }

        String token = header.substring(BEARER_PREFIX.length());
        if (!jwtTokenProvider.isValid(token)) {
            throw new MessagingException("Token JWT inválido ou expirado.");
        }

        UUID userId = jwtTokenProvider.getUserId(token);
        String email = jwtTokenProvider.getEmail(token);
        Role role = Role.valueOf(jwtTokenProvider.getRole(token));

        UserPrincipal principal = new UserPrincipal(userId, email, role);
        return new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
    }
}
