package com.enterprise.csui.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;

/**
 * Builds one RestClient per downstream microservice.
 *
 * Every RestClient adds an Authorization: Bearer <token> header via
 * KeycloakTokenService (client_credentials M2M grant).
 * The token is cached and auto-renewed 30s before expiry.
 */
@Configuration
public class WebClientConfig {

    private final KeycloakTokenService tokenService;

    public WebClientConfig(KeycloakTokenService tokenService) {
        this.tokenService = tokenService;
    }

    @Bean("crmClient")
    public RestClient crmClient(@Value("${services.crm.url}") String url) {
        return base(url);
    }

    @Bean("vendorClient")
    public RestClient vendorClient(@Value("${services.vendor.url}") String url) {
        return base(url);
    }

    @Bean("procurementClient")
    public RestClient procurementClient(@Value("${services.procurement.url}") String url) {
        return base(url);
    }

    @Bean("wmsInboundClient")
    public RestClient wmsInboundClient(@Value("${services.wms-inbound.url}") String url) {
        return base(url);
    }

    @Bean("omsClient")
    public RestClient omsClient(@Value("${services.oms.url}") String url) {
        return base(url);
    }

    @Bean("wmsOutboundClient")
    public RestClient wmsOutboundClient(@Value("${services.wms-outbound.url}") String url) {
        return base(url);
    }

    @Bean("tmsClient")
    public RestClient tmsClient(@Value("${services.tms.url}") String url) {
        return base(url);
    }

    private RestClient base(String baseUrl) {
        return RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader(HttpHeaders.ACCEPT,       MediaType.APPLICATION_JSON_VALUE)
                // Intercept every request and add the current Bearer token
                .requestInterceptor((request, body, execution) -> {
                    String token = tokenService.getBearerToken();
                    request.getHeaders().set(HttpHeaders.AUTHORIZATION, "Bearer " + token);
                    return execution.execute(request, body);
                })
                .build();
    }
}