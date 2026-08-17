package com.enterprise.csui.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.time.Instant;
import java.util.Map;

/**
 * Fetches a Keycloak client_credentials (M2M) Bearer token and caches it
 * until 30 seconds before expiry. Thread-safe via synchronized block.
 *
 * Used by WebClientConfig to add Authorization: Bearer <token> to every
 * outgoing RestClient call to the 7 secured Spring Boot REST APIs.
 */
@Component
@Slf4j
public class KeycloakTokenService {

    @Value("${keycloak.token-uri}")
    private String tokenUri;

    @Value("${keycloak.client-id}")
    private String clientId;

    @Value("${keycloak.client-secret}")
    private String clientSecret;

    private String cachedToken;
    private Instant expiresAt = Instant.MIN;

    private final RestClient http = RestClient.builder().build();

    public synchronized String getBearerToken() {
        if (cachedToken != null && Instant.now().isBefore(expiresAt)) {
            return cachedToken;
        }
        return fetchNewToken();
    }

    @SuppressWarnings("unchecked")
    private String fetchNewToken() {
        log.debug("Fetching new M2M access token from Keycloak...");

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type",    "client_credentials");
        form.add("client_id",     clientId);
        form.add("client_secret", clientSecret);

        Map<String, Object> response = http.post()
                .uri(tokenUri)
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(form)
                .retrieve()
                .body(Map.class);

        if (response == null || !response.containsKey("access_token")) {
            throw new IllegalStateException("Failed to obtain access token from Keycloak");
        }

        cachedToken = (String) response.get("access_token");
        int expiresIn = (Integer) response.getOrDefault("expires_in", 300);
        expiresAt = Instant.now().plusSeconds(expiresIn - 30); // 30s safety margin

        log.info("M2M access token acquired, expires in {}s", expiresIn);
        return cachedToken;
    }
}