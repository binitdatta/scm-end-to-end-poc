package com.enterprise.csprocurement.controller;

import com.enterprise.csprocurement.dto.request.ApprovePoRequest;
import com.enterprise.csprocurement.dto.request.CreatePoRequest;
import com.enterprise.csprocurement.dto.response.ApiResponse;
import com.enterprise.csprocurement.dto.response.PoEventResponse;
import com.enterprise.csprocurement.dto.response.PoResponse;
import com.enterprise.csprocurement.service.PurchaseOrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/purchase-orders")
@RequiredArgsConstructor
public class PurchaseOrderController {

    private final PurchaseOrderService poService;

    /** POST /api/v1/purchase-orders — Create PO in DRAFT */
    @PostMapping
    public ResponseEntity<ApiResponse<PoResponse>> createPo(
            @Valid @RequestBody CreatePoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(poService.createPo(request), "PO created successfully"));
    }

    /** GET /api/v1/purchase-orders — List all POs */
    @GetMapping
    public ResponseEntity<ApiResponse<List<PoResponse>>> getAllPos() {
        return ResponseEntity.ok(ApiResponse.ok(poService.getAllPos(), "POs retrieved"));
    }

    /** GET /api/v1/purchase-orders/{externalId} */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<PoResponse>> getPo(@PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(poService.getPo(externalId), "PO retrieved"));
    }

    /** GET /api/v1/purchase-orders/status/{status} */
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<PoResponse>>> getPosByStatus(
            @PathVariable String status) {
        return ResponseEntity.ok(
                ApiResponse.ok(poService.getPosByStatus(status.toUpperCase()),
                        "POs retrieved for status: " + status));
    }

    /** GET /api/v1/purchase-orders/{externalId}/events — Audit trail */
    @GetMapping("/{externalId}/events")
    public ResponseEntity<ApiResponse<List<PoEventResponse>>> getPoEvents(
            @PathVariable String externalId) {
        return ResponseEntity.ok(
                ApiResponse.ok(poService.getPoEvents(externalId), "PO events retrieved"));
    }

    /**
     * POST /api/v1/purchase-orders/{externalId}/approve
     * DRAFT → APPROVED. Publishes erp.procurement.po.approved
     */
    @PostMapping("/{externalId}/approve")
    public ResponseEntity<ApiResponse<PoResponse>> approvePo(
            @PathVariable String externalId,
            @Valid @RequestBody ApprovePoRequest request) {
        return ResponseEntity.ok(
                ApiResponse.ok(poService.approvePo(externalId, request), "PO approved"));
    }

    /**
     * POST /api/v1/purchase-orders/{externalId}/send
     * APPROVED → SENT_TO_VENDOR. Publishes erp.procurement.po.sent
     */
    @PostMapping("/{externalId}/send")
    public ResponseEntity<ApiResponse<PoResponse>> sendToVendor(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(poService.sendToVendor(externalId, by, notes),
                        "PO sent to vendor"));
    }

    /**
     * POST /api/v1/purchase-orders/{externalId}/acknowledge
     * SENT_TO_VENDOR → ACKNOWLEDGED. Publishes erp.procurement.po.acknowledged
     */
    @PostMapping("/{externalId}/acknowledge")
    public ResponseEntity<ApiResponse<PoResponse>> acknowledgePo(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(poService.acknowledgePo(externalId, by, notes),
                        "PO acknowledged by vendor"));
    }

    /**
     * POST /api/v1/purchase-orders/{externalId}/in-production
     * ACKNOWLEDGED → IN_PRODUCTION. Publishes erp.procurement.po.in-production
     */
    @PostMapping("/{externalId}/in-production")
    public ResponseEntity<ApiResponse<PoResponse>> markInProduction(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(poService.markInProduction(externalId, by, notes),
                        "PO marked in production"));
    }

    /**
     * POST /api/v1/purchase-orders/{externalId}/ready-to-ship
     * IN_PRODUCTION → READY_TO_SHIP. Publishes erp.procurement.po.ready-to-ship
     * KEY EVENT — WMS Inbound subscribes to this to schedule receiving.
     */
    @PostMapping("/{externalId}/ready-to-ship")
    public ResponseEntity<ApiResponse<PoResponse>> markReadyToShip(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by       = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes    = body != null ? body.get("notes") : null;
        String shipDate = body != null ? body.get("estimatedShipDate") : null;
        LocalDate date  = (shipDate != null) ? LocalDate.parse(shipDate) : null;
        return ResponseEntity.ok(
                ApiResponse.ok(poService.markReadyToShip(externalId, by, notes, date),
                        "PO ready to ship"));
    }

    /**
     * POST /api/v1/purchase-orders/{externalId}/complete
     * READY_TO_SHIP → COMPLETED. Publishes erp.procurement.po.completed
     */
    @PostMapping("/{externalId}/complete")
    public ResponseEntity<ApiResponse<PoResponse>> completePo(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(poService.completePo(externalId, by, notes), "PO completed"));
    }

    /**
     * POST /api/v1/purchase-orders/{externalId}/cancel
     * → CANCELLED. Publishes erp.procurement.po.cancelled
     */
    @PostMapping("/{externalId}/cancel")
    public ResponseEntity<ApiResponse<PoResponse>> cancelPo(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(poService.cancelPo(externalId, by, notes), "PO cancelled"));
    }
}
