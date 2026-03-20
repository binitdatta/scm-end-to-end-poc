package com.enterprise.csui.controller;

import com.enterprise.csui.client.ProxyClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClient;

import java.util.Map;

/**
 * Single pass-through REST controller.
 * The frontend JS calls /api/proxy/{service}/{**path}
 * and we forward to the correct downstream microservice.
 *
 * GET  /api/proxy/{service}/**  → GET  downstream
 * POST /api/proxy/{service}/**  → POST downstream
 */
@RestController
@RequestMapping("/api/proxy")
@RequiredArgsConstructor
public class ApiController {

    private final ProxyClient   proxy;
    private final RestClient    crmClient;
    private final RestClient    vendorClient;
    private final RestClient    procurementClient;
    private final RestClient    wmsInboundClient;
    private final RestClient    omsClient;
    private final RestClient    wmsOutboundClient;
    private final RestClient    tmsClient;

    @GetMapping("/{service}/**")
    public JsonNode proxyGet(@PathVariable String service,
                              jakarta.servlet.http.HttpServletRequest request) {
        String path = extractPath(request, "/api/proxy/" + service);
        return proxy.get(resolveClient(service), path);
    }

    @PostMapping("/{service}/**")
    public JsonNode proxyPost(@PathVariable String service,
                               @RequestBody(required = false) Map<String, Object> body,
                               jakarta.servlet.http.HttpServletRequest request) {
        String path = extractPath(request, "/api/proxy/" + service);
        return proxy.post(resolveClient(service), path, body != null ? body : Map.of());
    }

    private String extractPath(jakarta.servlet.http.HttpServletRequest req, String prefix) {
        String uri = req.getRequestURI();
        String path = uri.startsWith(prefix) ? uri.substring(prefix.length()) : uri;
        String query = req.getQueryString();
        return (path.isBlank() ? "/" : path) + (query != null ? "?" + query : "");
    }

    private RestClient resolveClient(String service) {
        return switch (service.toLowerCase()) {
            case "crm"           -> crmClient;
            case "vendor"        -> vendorClient;
            case "procurement"   -> procurementClient;
            case "wms-inbound"   -> wmsInboundClient;
            case "oms"           -> omsClient;
            case "wms-outbound"  -> wmsOutboundClient;
            case "tms"           -> tmsClient;
            default              -> crmClient;
        };
    }
}
