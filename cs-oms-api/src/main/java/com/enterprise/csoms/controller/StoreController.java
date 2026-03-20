package com.enterprise.csoms.controller;

import com.enterprise.csoms.dto.response.ApiResponse;
import com.enterprise.csoms.dto.response.RegionResponse;
import com.enterprise.csoms.dto.response.StoreResponse;
import com.enterprise.csoms.service.StoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class StoreController {

    private final StoreService storeService;

    /** GET /api/v1/regions — List all regions */
    @GetMapping("/api/v1/regions")
    public ResponseEntity<ApiResponse<List<RegionResponse>>> getAllRegions() {
        return ResponseEntity.ok(ApiResponse.ok(
                storeService.getAllRegions(), "Regions retrieved"));
    }

    /** GET /api/v1/regions/{regionCode} — Get region by code */
    @GetMapping("/api/v1/regions/{regionCode}")
    public ResponseEntity<ApiResponse<RegionResponse>> getRegion(
            @PathVariable String regionCode) {
        return ResponseEntity.ok(ApiResponse.ok(
                storeService.getRegion(regionCode.toUpperCase()),
                "Region retrieved"));
    }

    /** GET /api/v1/regions/{regionCode}/stores — All stores in a region */
    @GetMapping("/api/v1/regions/{regionCode}/stores")
    public ResponseEntity<ApiResponse<List<StoreResponse>>> getStoresByRegion(
            @PathVariable String regionCode) {
        return ResponseEntity.ok(ApiResponse.ok(
                storeService.getStoresByRegion(regionCode.toUpperCase()),
                "Stores retrieved for region: " + regionCode));
    }

    /** GET /api/v1/stores — List all stores */
    @GetMapping("/api/v1/stores")
    public ResponseEntity<ApiResponse<List<StoreResponse>>> getAllStores() {
        return ResponseEntity.ok(ApiResponse.ok(
                storeService.getAllStores(), "Stores retrieved"));
    }
}
