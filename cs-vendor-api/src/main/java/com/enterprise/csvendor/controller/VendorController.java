package com.enterprise.csvendor.controller;

import com.enterprise.csvendor.dto.request.CreateVendorRequest;
import com.enterprise.csvendor.dto.response.ApiResponse;
import com.enterprise.csvendor.dto.response.VendorResponse;
import com.enterprise.csvendor.service.VendorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/vendors")
@RequiredArgsConstructor
public class VendorController {

    private final VendorService vendorService;

    /**
     * POST /api/v1/vendors
     * Register a new vendor. Publishes erp.vendor.vendor.created
     */
    @PostMapping
    public ResponseEntity<ApiResponse<VendorResponse>> createVendor(
            @Valid @RequestBody CreateVendorRequest request) {
        VendorResponse response = vendorService.createVendor(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Vendor created successfully"));
    }

    /**
     * GET /api/v1/vendors
     * List all vendors.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<VendorResponse>>> getAllVendors() {
        return ResponseEntity.ok(ApiResponse.ok(vendorService.getAllVendors(), "Vendors retrieved"));
    }

    /**
     * GET /api/v1/vendors/{externalId}
     * Get a single vendor by external UUID.
     */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<VendorResponse>> getVendor(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(vendorService.getVendor(externalId), "Vendor retrieved"));
    }

    /**
     * GET /api/v1/vendors/country/{country}
     * List active vendors by sourcing country (CHINA | VIETNAM | INDIA | THAILAND)
     */
    @GetMapping("/country/{country}")
    public ResponseEntity<ApiResponse<List<VendorResponse>>> getVendorsByCountry(
            @PathVariable String country) {
        return ResponseEntity.ok(
                ApiResponse.ok(vendorService.getVendorsByCountry(country.toUpperCase()),
                        "Vendors retrieved for country: " + country));
    }

    /**
     * PATCH /api/v1/vendors/{externalId}/scorecard
     * Update vendor scorecard rating (0.0 to 5.0)
     */
    @PatchMapping("/{externalId}/scorecard")
    public ResponseEntity<ApiResponse<VendorResponse>> updateScorecard(
            @PathVariable String externalId,
            @RequestBody Map<String, BigDecimal> body) {
        BigDecimal rating = body.get("rating");
        if (rating == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Request body must contain 'rating' field"));
        }
        return ResponseEntity.ok(
                ApiResponse.ok(vendorService.updateScorecard(externalId, rating),
                        "Scorecard updated"));
    }
}
