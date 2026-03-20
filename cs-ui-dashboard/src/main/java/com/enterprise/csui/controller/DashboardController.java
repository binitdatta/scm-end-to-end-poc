package com.enterprise.csui.controller;

import com.enterprise.csui.client.ProxyClient;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.client.RestClient;

import java.util.LinkedHashMap;
import java.util.Map;

@Controller
@RequiredArgsConstructor
public class DashboardController {

    private final ProxyClient  proxy;
    private final RestClient   crmClient;
    private final RestClient   vendorClient;
    private final RestClient   procurementClient;
    private final RestClient   wmsInboundClient;
    private final RestClient   omsClient;
    private final RestClient   wmsOutboundClient;
    private final RestClient   tmsClient;

    @GetMapping("/")
    public String home(Model model) {
        Map<String, String> health = new LinkedHashMap<>();
        health.put("CRM (8081)",          status(crmClient));
        health.put("Vendor (8082)",        status(vendorClient));
        health.put("Procurement (8083)",   status(procurementClient));
        health.put("WMS Inbound (8084)",   status(wmsInboundClient));
        health.put("OMS (8085)",           status(omsClient));
        health.put("WMS Outbound (8086)",  status(wmsOutboundClient));
        health.put("TMS (8087)",           status(tmsClient));

        long up = health.values().stream().filter("UP"::equals).count();
        model.addAttribute("health", health);
        model.addAttribute("upCount", up);
        model.addAttribute("totalCount", health.size());
        model.addAttribute("activePage", "home");
        return "pages/home";
    }

    private String status(RestClient client) {
        try {
            JsonNode node = proxy.get(client, "/actuator/health");
            if (node != null && node.has("status")) {
                return node.get("status").asText();
            }
            return "DOWN";
        } catch (Exception e) {
            return "DOWN";
        }
    }
}
