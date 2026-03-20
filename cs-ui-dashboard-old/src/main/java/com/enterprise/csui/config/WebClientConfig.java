package com.enterprise.csui.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;

@Configuration
public class WebClientConfig {

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
                .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }
}
