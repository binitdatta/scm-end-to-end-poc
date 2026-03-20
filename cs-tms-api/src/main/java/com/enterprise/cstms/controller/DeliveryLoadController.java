package com.enterprise.cstms.controller;

import com.enterprise.cstms.dto.request.*;
import com.enterprise.cstms.dto.response.*;
import com.enterprise.cstms.service.DeliveryLoadService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/delivery-loads")
@RequiredArgsConstructor
public class DeliveryLoadController {

    private final DeliveryLoadService loadService;

    /** POST /api/v1/delivery-loads — Create load from WMS dispatch. Publishes erp.tms.load.created */
    @PostMapping
    public ResponseEntity<ApiResponse<DeliveryLoadResponse>> createLoad(
            @Valid @RequestBody CreateDeliveryLoadRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(loadService.createLoad(request), "Delivery load created"));
    }

    /** GET /api/v1/delivery-loads */
    @GetMapping
    public ResponseEntity<ApiResponse<List<DeliveryLoadResponse>>> getAllLoads() {
        return ResponseEntity.ok(ApiResponse.ok(loadService.getAllLoads(), "Loads retrieved"));
    }

    /** GET /api/v1/delivery-loads/{externalId} */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<DeliveryLoadResponse>> getLoad(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(loadService.getLoad(externalId), "Load retrieved"));
    }

    /** GET /api/v1/delivery-loads/status/{status} */
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<DeliveryLoadResponse>>> getByStatus(
            @PathVariable String status) {
        return ResponseEntity.ok(ApiResponse.ok(
                loadService.getLoadsByStatus(status.toUpperCase()),
                "Loads for status: " + status));
    }

    /** GET /api/v1/delivery-loads/campaign/{campaignCode} */
    @GetMapping("/campaign/{campaignCode}")
    public ResponseEntity<ApiResponse<List<DeliveryLoadResponse>>> getByCampaign(
            @PathVariable String campaignCode) {
        return ResponseEntity.ok(ApiResponse.ok(
                loadService.getLoadsByCampaign(campaignCode),
                "Loads for campaign: " + campaignCode));
    }

    /** GET /api/v1/delivery-loads/{externalId}/transit-events */
    @GetMapping("/{externalId}/transit-events")
    public ResponseEntity<ApiResponse<List<TransitEventResponse>>> getTransitEvents(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(
                loadService.getTransitEvents(externalId), "Transit events retrieved"));
    }

    /** GET /api/v1/delivery-loads/{externalId}/events */
    @GetMapping("/{externalId}/events")
    public ResponseEntity<ApiResponse<List<TmsEventResponse>>> getTmsEvents(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(
                loadService.getTmsEvents(externalId), "TMS events retrieved"));
    }

    /**
     * POST /api/v1/delivery-loads/{externalId}/assign
     * CREATED → ASSIGNED. Assigns driver and truck.
     * Publishes erp.tms.load.assigned
     */
    @PostMapping("/{externalId}/assign")
    public ResponseEntity<ApiResponse<DeliveryLoadResponse>> assignDriver(
            @PathVariable String externalId,
            @Valid @RequestBody AssignDriverRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                loadService.assignDriver(externalId, request), "Driver assigned to load"));
    }

    /**
     * POST /api/v1/delivery-loads/{externalId}/in-transit
     * ASSIGNED → IN_TRANSIT. All store deliveries become OUT_FOR_DELIVERY.
     * Publishes erp.tms.load.in-transit and erp.tms.delivery.out-for-delivery
     */
    @PostMapping("/{externalId}/in-transit")
    public ResponseEntity<ApiResponse<DeliveryLoadResponse>> markInTransit(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "tms.coordinator") : "tms.coordinator";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                loadService.markInTransit(externalId, by, notes), "Load in transit"));
    }

    /**
     * POST /api/v1/delivery-loads/{externalId}/transit-events
     * Append a carrier tracking milestone.
     */
    @PostMapping("/{externalId}/transit-events")
    public ResponseEntity<ApiResponse<TransitEventResponse>> recordTransitEvent(
            @PathVariable String externalId,
            @Valid @RequestBody RecordTransitEventRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(
                        loadService.recordTransitEvent(externalId, request),
                        "Transit event recorded"));
    }

    /**
     * POST /api/v1/delivery-loads/{externalId}/store-deliveries/{storeDeliveryExternalId}/pod
     * Confirm POD at a specific store.
     * When ALL stores confirm POD → load auto-completes and publishes
     * erp.tms.delivery.pod-confirmed — the FINAL supply chain event.
     */
    @PostMapping("/{externalId}/store-deliveries/{storeDeliveryExternalId}/pod")
    public ResponseEntity<ApiResponse<StoreDeliveryResponse>> confirmPod(
            @PathVariable String externalId,
            @PathVariable String storeDeliveryExternalId,
            @Valid @RequestBody ConfirmPodRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                loadService.confirmPod(externalId, storeDeliveryExternalId, request),
                "POD confirmed"));
    }
}
