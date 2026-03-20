package com.enterprise.csui;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties
public class CsUiDashboardApplication {
    public static void main(String[] args) {
        SpringApplication.run(CsUiDashboardApplication.class, args);
    }
}
