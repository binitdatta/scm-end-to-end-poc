package com.enterprise.cswmsinbound.controller;

import com.enterprise.cswmsinbound.dto.request.CompletePutawayRequest;
import com.enterprise.cswmsinbound.dto.request.CreateAsnRequest;
import com.enterprise.cswmsinbound.dto.request.ReceiveShipmentRequest;
import com.enterprise.cswmsinbound.dto.response.*;
import com.enterprise.cswmsinbound.service.AsnService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/asns")
@RequiredArgsConstructor
public class AsnController {

    private final AsnService asnService;

    /** POST /api/v1/asns — Create ASN. Publishes erp.wms.inbound.asn.created */
    @PostMapping
    public ResponseEntity<ApiResponse<AsnResponse>> createAsn(
            @Valid @RequestBody CreateAsnRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(asnService.createAsn(request), "ASN created successfully"));
    }

    /** GET /api/v1/asns */
    @GetMapping
    public ResponseEntity<ApiResponse<List<AsnResponse>>> getAllAsns() {
        return ResponseEntity.ok(ApiResponse.ok(asnService.getAllAsns(), "ASNs retrieved"));
    }

    /** GET /api/v1/asns/{externalId} */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<AsnResponse>> getAsn(@PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(asnService.getAsn(externalId), "ASN retrieved"));
    }

    /** GET /api/v1/asns/status/{status} */
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<AsnResponse>>> getAsnsByStatus(
            @PathVariable String status) {
        return ResponseEntity.ok(
                ApiResponse.ok(asnService.getAsnsByStatus(status.toUpperCase()),
                        "ASNs retrieved for status: " + status));
    }

    /**
     * POST /api/v1/asns/{externalId}/schedule
     * CREATED → SCHEDULED. Publishes erp.wms.inbound.asn.scheduled
     */
    @PostMapping("/{externalId}/schedule")
    public ResponseEntity<ApiResponse<AsnResponse>> scheduleDock(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String apptStr  = body != null ? body.get("dockAppointmentDate") : null;
        String dockDoor = body != null ? body.getOrDefault("dockDoor", "DOOR-01") : "DOOR-01";
        String by       = body != null ? body.getOrDefault("triggeredBy", "wms.coordinator") : "wms.coordinator";
        LocalDateTime appt = apptStr != null
                ? LocalDateTime.parse(apptStr)
                : LocalDateTime.now().plusDays(1).withHour(8).withMinute(0);
        return ResponseEntity.ok(
                ApiResponse.ok(asnService.scheduleDock(externalId, appt, dockDoor, by),
                        "Dock appointment scheduled"));
    }

    /**
     * POST /api/v1/asns/{externalId}/in-transit
     * SCHEDULED → IN_TRANSIT
     */
    @PostMapping("/{externalId}/in-transit")
    public ResponseEntity<ApiResponse<AsnResponse>> markInTransit(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(asnService.markInTransit(externalId, by, notes),
                        "ASN marked in transit"));
    }

    /**
     * POST /api/v1/asns/{externalId}/arrived
     * IN_TRANSIT/SCHEDULED → ARRIVED. Publishes erp.wms.inbound.shipment.arrived
     */
    @PostMapping("/{externalId}/arrived")
    public ResponseEntity<ApiResponse<AsnResponse>> markArrived(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by          = body != null ? body.getOrDefault("triggeredBy", "wms.coordinator") : "wms.coordinator";
        String notes       = body != null ? body.get("notes") : null;
        String dateStr     = body != null ? body.get("arrivalDate") : null;
        LocalDate arrDate  = dateStr != null ? LocalDate.parse(dateStr) : LocalDate.now();
        return ResponseEntity.ok(
                ApiResponse.ok(asnService.markArrived(externalId, arrDate, by, notes),
                        "Shipment marked arrived"));
    }

    /**
     * POST /api/v1/asns/{externalId}/receive
     * ARRIVED → RECEIVED. Publishes erp.wms.inbound.receiving.completed
     */
    @PostMapping("/{externalId}/receive")
    public ResponseEntity<ApiResponse<ReceivingResponse>> receiveShipment(
            @PathVariable String externalId,
            @Valid @RequestBody ReceiveShipmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(asnService.receiveShipment(externalId, request),
                        "Shipment received successfully"));
    }

    /**
     * GET /api/v1/asns/{externalId}/receiving
     * Get the receiving record for an ASN.
     */
    @GetMapping("/{externalId}/receiving")
    public ResponseEntity<ApiResponse<ReceivingResponse>> getReceivingRecord(
            @PathVariable String externalId) {
        return ResponseEntity.ok(
                ApiResponse.ok(asnService.getReceivingRecord(externalId),
                        "Receiving record retrieved"));
    }

    /**
     * POST /api/v1/asns/{externalId}/putaway
     * RECEIVED → PUTAWAY_COMPLETED.
     * Publishes erp.wms.inbound.putaway.completed — KEY event for cs-oms-api
     */
    @PostMapping("/{externalId}/putaway")
    public ResponseEntity<ApiResponse<PutawayResponse>> completePutaway(
            @PathVariable String externalId,
            @Valid @RequestBody CompletePutawayRequest request) {
        return ResponseEntity.ok(
                ApiResponse.ok(asnService.completePutaway(externalId, request),
                        "Putaway completed successfully"));
    }

    /** GET /api/v1/asns/{externalId}/events — Audit trail */
    @GetMapping("/{externalId}/events")
    public ResponseEntity<ApiResponse<List<AsnEventResponse>>> getAsnEvents(
            @PathVariable String externalId) {
        return ResponseEntity.ok(
                ApiResponse.ok(asnService.getAsnEvents(externalId), "ASN events retrieved"));
    }
}
