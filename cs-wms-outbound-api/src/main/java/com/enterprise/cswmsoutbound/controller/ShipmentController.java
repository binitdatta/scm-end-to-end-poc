package com.enterprise.cswmsoutbound.controller;

import com.enterprise.cswmsoutbound.dto.request.CreateShipmentRequest;
import com.enterprise.cswmsoutbound.dto.request.ManifestShipmentRequest;
import com.enterprise.cswmsoutbound.dto.response.ApiResponse;
import com.enterprise.cswmsoutbound.dto.response.OutboundEventResponse;
import com.enterprise.cswmsoutbound.dto.response.ShipmentResponse;
import com.enterprise.cswmsoutbound.service.ShipmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/shipments")
@RequiredArgsConstructor
public class ShipmentController {

    private final ShipmentService shipmentService;

    /** POST /api/v1/shipments — Create shipment from completed wave. Publishes erp.wms.outbound.shipment.created */
    @PostMapping
    public ResponseEntity<ApiResponse<ShipmentResponse>> createShipment(
            @Valid @RequestBody CreateShipmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(shipmentService.createShipment(request),
                        "Shipment created successfully"));
    }

    /** GET /api/v1/shipments */
    @GetMapping
    public ResponseEntity<ApiResponse<List<ShipmentResponse>>> getAllShipments() {
        return ResponseEntity.ok(ApiResponse.ok(shipmentService.getAllShipments(), "Shipments retrieved"));
    }

    /** GET /api/v1/shipments/{externalId} */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<ShipmentResponse>> getShipment(@PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(
                shipmentService.getShipment(externalId), "Shipment retrieved"));
    }

    /** GET /api/v1/shipments/status/{status} */
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<ShipmentResponse>>> getByStatus(@PathVariable String status) {
        return ResponseEntity.ok(ApiResponse.ok(
                shipmentService.getShipmentsByStatus(status.toUpperCase()),
                "Shipments for status: " + status));
    }

    /** GET /api/v1/shipments/campaign/{campaignCode} */
    @GetMapping("/campaign/{campaignCode}")
    public ResponseEntity<ApiResponse<List<ShipmentResponse>>> getByCampaign(
            @PathVariable String campaignCode) {
        return ResponseEntity.ok(ApiResponse.ok(
                shipmentService.getShipmentsByCampaign(campaignCode),
                "Shipments for campaign: " + campaignCode));
    }

    /** GET /api/v1/shipments/{externalId}/events */
    @GetMapping("/{externalId}/events")
    public ResponseEntity<ApiResponse<List<OutboundEventResponse>>> getShipmentEvents(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(
                shipmentService.getShipmentEvents(externalId), "Shipment events retrieved"));
    }

    /**
     * POST /api/v1/shipments/{externalId}/pack
     * CREATED → PACKED. Publishes erp.wms.outbound.shipment.packed
     */
    @PostMapping("/{externalId}/pack")
    public ResponseEntity<ApiResponse<ShipmentResponse>> packShipment(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "wms.outbound.packer") : "wms.outbound.packer";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                shipmentService.packShipment(externalId, by, notes), "Shipment packed"));
    }

    /**
     * POST /api/v1/shipments/{externalId}/manifest
     * PACKED → MANIFESTED. Assigns carrier and PRO number.
     * Publishes erp.wms.outbound.shipment.manifested
     */
    @PostMapping("/{externalId}/manifest")
    public ResponseEntity<ApiResponse<ShipmentResponse>> manifestShipment(
            @PathVariable String externalId,
            @Valid @RequestBody ManifestShipmentRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                shipmentService.manifestShipment(externalId, request), "Shipment manifested"));
    }

    /**
     * POST /api/v1/shipments/{externalId}/dispatch
     * MANIFESTED → DISPATCHED.
     * Publishes erp.wms.outbound.shipment.dispatched — KEY event for cs-tms-api.
     */
    @PostMapping("/{externalId}/dispatch")
    public ResponseEntity<ApiResponse<ShipmentResponse>> dispatchShipment(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "wms.outbound.coordinator") : "wms.outbound.coordinator";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                shipmentService.dispatchShipment(externalId, by, notes), "Shipment dispatched"));
    }
}
