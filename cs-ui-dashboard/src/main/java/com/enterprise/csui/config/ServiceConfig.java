package com.enterprise.csui.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "services")
@Getter @Setter
public class ServiceConfig {
    private String crmUrl        = "http://localhost:8081";
    private String vendorUrl     = "http://localhost:8082";
    private String procurementUrl= "http://localhost:8083";
    private String wmsInboundUrl = "http://localhost:8084";
    private String omsUrl        = "http://localhost:8085";
    private String wmsOutboundUrl= "http://localhost:8086";
    private String tmsUrl        = "http://localhost:8087";
    private int    timeoutSeconds= 10;
}
