package com.enterprise.csoms.controller;

import com.enterprise.csoms.dto.request.UpdateInventoryRequest;
import com.enterprise.csoms.dto.response.ApiResponse;
import com.enterprise.csoms.dto.response.InventoryAvailabilityResponse;
import com.enterprise.csoms.service.InventoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    /**
     * POST /api/v1/inventory/update
     * Upserts the OMS inventory view for a SKU + campaign.
     * Called manually to simulate what would happen when
     * erp.wms.inbound.putaway.completed is consumed.
     * Publishes erp.oms.inventory.updated to the Control Tower.
     */
    @PostMapping("/update")
    public ResponseEntity<ApiResponse<InventoryAvailabilityResponse>> updateInventory(
            @Valid @RequestBody UpdateInventoryRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                inventoryService.updateInventory(request),
                "Inventory updated successfully"));
    }

    /**
     * GET /api/v1/inventory/campaign/{campaignCode}
     * All SKUs available for a campaign.
     */
    @GetMapping("/campaign/{campaignCode}")
    public ResponseEntity<ApiResponse<List<InventoryAvailabilityResponse>>> getByCampaign(
            @PathVariable String campaignCode) {
        return ResponseEntity.ok(ApiResponse.ok(
                inventoryService.getInventoryByCampaign(campaignCode),
                "Inventory retrieved for campaign: " + campaignCode));
    }

    /**
     * GET /api/v1/inventory/sku/{sku}/campaign/{campaignCode}
     * Single SKU availability for a specific campaign.
     */
    @GetMapping("/sku/{sku}/campaign/{campaignCode}")
    public ResponseEntity<ApiResponse<InventoryAvailabilityResponse>> getBySku(
            @PathVariable String sku,
            @PathVariable String campaignCode) {
        return ResponseEntity.ok(ApiResponse.ok(
                inventoryService.getInventory(sku, campaignCode),
                "Inventory retrieved for SKU: " + sku));
    }
}
