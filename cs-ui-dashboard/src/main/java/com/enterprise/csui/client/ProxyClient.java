package com.enterprise.csui.client;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;

/**
 * Generic proxy — wraps every downstream call and catches errors gracefully.
 * Returns JsonNode so the UI can render whatever the microservice returns
 * without needing strongly-typed DTOs in the dashboard layer.
 */
@Component
@Slf4j
public class ProxyClient {

    public JsonNode get(RestClient client, String path) {
        try {
            return client.get()
                    .uri(path)
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientException ex) {
            log.warn("GET {} failed: {}", path, ex.getMessage());
            return null;
        } catch (Exception ex) {
            log.error("GET {} unexpected: {}", path, ex.getMessage());
            return null;
        }
    }

    public JsonNode post(RestClient client, String path, Object body) {
        try {
            return client.post()
                    .uri(path)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);
        } catch (RestClientException ex) {
            log.warn("POST {} failed: {}", path, ex.getMessage());
            return errorNode(ex.getMessage());
        } catch (Exception ex) {
            log.error("POST {} unexpected: {}", path, ex.getMessage());
            return errorNode(ex.getMessage());
        }
    }

    private JsonNode errorNode(String msg) {
        try {
            com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
            return om.readTree("{\"success\":false,\"message\":\"" +
                    (msg != null ? msg.replace("\"", "'") : "Unknown error") + "\"}");
        } catch (Exception e) {
            return null;
        }
    }
}
