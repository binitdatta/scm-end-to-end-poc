package com.enterprise.cswmsoutbound.controller;

import com.enterprise.cswmsoutbound.dto.request.CreatePickWaveRequest;
import com.enterprise.cswmsoutbound.dto.response.ApiResponse;
import com.enterprise.cswmsoutbound.dto.response.OutboundEventResponse;
import com.enterprise.cswmsoutbound.dto.response.PickWaveResponse;
import com.enterprise.cswmsoutbound.service.PickWaveService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/pick-waves")
@RequiredArgsConstructor
public class PickWaveController {

    private final PickWaveService waveService;

    /** POST /api/v1/pick-waves — Create pick wave. Publishes erp.wms.outbound.wave.created */
    @PostMapping
    public ResponseEntity<ApiResponse<PickWaveResponse>> createWave(
            @Valid @RequestBody CreatePickWaveRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(waveService.createWave(request), "Pick wave created"));
    }

    /** GET /api/v1/pick-waves */
    @GetMapping
    public ResponseEntity<ApiResponse<List<PickWaveResponse>>> getAllWaves() {
        return ResponseEntity.ok(ApiResponse.ok(waveService.getAllWaves(), "Pick waves retrieved"));
    }

    /** GET /api/v1/pick-waves/{externalId} */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<PickWaveResponse>> getWave(@PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(waveService.getWave(externalId), "Pick wave retrieved"));
    }

    /** GET /api/v1/pick-waves/status/{status} */
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<PickWaveResponse>>> getByStatus(@PathVariable String status) {
        return ResponseEntity.ok(ApiResponse.ok(
                waveService.getWavesByStatus(status.toUpperCase()), "Waves for status: " + status));
    }

    /** GET /api/v1/pick-waves/{externalId}/events */
    @GetMapping("/{externalId}/events")
    public ResponseEntity<ApiResponse<List<OutboundEventResponse>>> getWaveEvents(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(
                waveService.getWaveEvents(externalId), "Wave events retrieved"));
    }

    /** POST /api/v1/pick-waves/{externalId}/assign — CREATED → ASSIGNED */
    @PostMapping("/{externalId}/assign")
    public ResponseEntity<ApiResponse<PickWaveResponse>> assignWave(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("assignedTo", "picker.team.01") : "picker.team.01";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                waveService.assignWave(externalId, by, notes), "Wave assigned"));
    }

    /** POST /api/v1/pick-waves/{externalId}/start — → PICKING */
    @PostMapping("/{externalId}/start")
    public ResponseEntity<ApiResponse<PickWaveResponse>> startPicking(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "picker.team.01") : "picker.team.01";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                waveService.startPicking(externalId, by, notes), "Picking started"));
    }

    /**
     * POST /api/v1/pick-waves/{externalId}/complete
     * PICKING → COMPLETED. Publishes erp.wms.outbound.wave.completed
     */
    @PostMapping("/{externalId}/complete")
    public ResponseEntity<ApiResponse<PickWaveResponse>> completeWave(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, Object> body) {
        String by    = body != null ? (String) body.getOrDefault("triggeredBy", "picker.team.01") : "picker.team.01";
        String notes = body != null ? (String) body.get("notes") : null;
        int picked   = body != null && body.containsKey("pickedQuantity")
                ? ((Number) body.get("pickedQuantity")).intValue()
                : waveService.findWaveOrThrow(externalId).getTotalQuantity();
        return ResponseEntity.ok(ApiResponse.ok(
                waveService.completeWave(externalId, picked, by, notes), "Wave completed"));
    }
}
