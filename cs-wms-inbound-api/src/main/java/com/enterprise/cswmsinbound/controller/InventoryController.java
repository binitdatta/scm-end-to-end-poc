package com.enterprise.cswmsinbound.controller;

import com.enterprise.cswmsinbound.dto.response.ApiResponse;
import com.enterprise.cswmsinbound.dto.response.InventoryResponse;
import com.enterprise.cswmsinbound.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    /** GET /api/v1/inventory/sku/{sku} — All bin locations for a SKU */
    @GetMapping("/sku/{sku}")
    public ResponseEntity<ApiResponse<List<InventoryResponse>>> getBySku(
            @PathVariable String sku) {
        return ResponseEntity.ok(
                ApiResponse.ok(inventoryService.getInventoryBySku(sku),
                        "Inventory retrieved for SKU: " + sku));
    }

    /** GET /api/v1/inventory/campaign/{campaignCode} — All inventory for a campaign */
    @GetMapping("/campaign/{campaignCode}")
    public ResponseEntity<ApiResponse<List<InventoryResponse>>> getByCampaign(
            @PathVariable String campaignCode) {
        return ResponseEntity.ok(
                ApiResponse.ok(inventoryService.getInventoryByCampaign(campaignCode),
                        "Inventory retrieved for campaign: " + campaignCode));
    }

    /** GET /api/v1/inventory/sku/{sku}/available — Total available quantity */
    @GetMapping("/sku/{sku}/available")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAvailableBySku(
            @PathVariable String sku) {
        Integer qty = inventoryService.getTotalAvailableBySku(sku);
        return ResponseEntity.ok(
                ApiResponse.ok(Map.of("sku", sku, "totalAvailable", qty),
                        "Available quantity for SKU: " + sku));
    }

    /** GET /api/v1/inventory/campaign/{campaignCode}/on-hand — Total on-hand */
    @GetMapping("/campaign/{campaignCode}/on-hand")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOnHandByCampaign(
            @PathVariable String campaignCode) {
        Integer qty = inventoryService.getTotalOnHandByCampaign(campaignCode);
        return ResponseEntity.ok(
                ApiResponse.ok(Map.of("campaignCode", campaignCode, "totalOnHand", qty),
                        "On-hand quantity for campaign: " + campaignCode));
    }
}
