package com.enterprise.csvendor.controller;

import com.enterprise.csvendor.dto.request.AwardRfqRequest;
import com.enterprise.csvendor.dto.request.CreateRfqRequest;
import com.enterprise.csvendor.dto.request.SubmitQuoteRequest;
import com.enterprise.csvendor.dto.response.*;
import com.enterprise.csvendor.service.RfqService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/rfqs")
@RequiredArgsConstructor
public class RfqController {

    private final RfqService rfqService;

    /**
     * POST /api/v1/rfqs
     * Create an RFQ in DRAFT status. Optionally invite vendors immediately.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<RfqResponse>> createRfq(
            @Valid @RequestBody CreateRfqRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(rfqService.createRfq(request), "RFQ created successfully"));
    }

    /**
     * GET /api/v1/rfqs
     * List all RFQs.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<RfqResponse>>> getAllRfqs() {
        return ResponseEntity.ok(ApiResponse.ok(rfqService.getAllRfqs(), "RFQs retrieved"));
    }

    /**
     * GET /api/v1/rfqs/{externalId}
     * Get a single RFQ by external UUID.
     */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<RfqResponse>> getRfq(@PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(rfqService.getRfq(externalId), "RFQ retrieved"));
    }

    /**
     * POST /api/v1/rfqs/{externalId}/open
     * Transition RFQ from DRAFT → OPEN. Publishes erp.vendor.rfq.opened
     */
    @PostMapping("/{externalId}/open")
    public ResponseEntity<ApiResponse<RfqResponse>> openRfq(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String triggeredBy = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        return ResponseEntity.ok(
                ApiResponse.ok(rfqService.openRfq(externalId, triggeredBy), "RFQ opened"));
    }

    /**
     * POST /api/v1/rfqs/{externalId}/quotes
     * Vendor submits a quote for an OPEN RFQ.
     * Publishes erp.vendor.quote.submitted
     */
    @PostMapping("/{externalId}/quotes")
    public ResponseEntity<ApiResponse<QuoteResponse>> submitQuote(
            @PathVariable String externalId,
            @Valid @RequestBody SubmitQuoteRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(rfqService.submitQuote(externalId, request),
                        "Quote submitted successfully"));
    }

    /**
     * GET /api/v1/rfqs/{externalId}/quotes
     * List all quotes received for an RFQ — side-by-side vendor comparison.
     */
    @GetMapping("/{externalId}/quotes")
    public ResponseEntity<ApiResponse<List<QuoteResponse>>> getQuotes(
            @PathVariable String externalId) {
        return ResponseEntity.ok(
                ApiResponse.ok(rfqService.getQuotesForRfq(externalId), "Quotes retrieved"));
    }

    /**
     * POST /api/v1/rfqs/{externalId}/award
     * Award the RFQ to the winning vendor.
     * Publishes erp.vendor.rfq.awarded — the KEY event that triggers PO creation
     * in cs-procurement-api via the Control Tower.
     */
    @PostMapping("/{externalId}/award")
    public ResponseEntity<ApiResponse<AwardResponse>> awardRfq(
            @PathVariable String externalId,
            @Valid @RequestBody AwardRfqRequest request) {
        return ResponseEntity.ok(
                ApiResponse.ok(rfqService.awardRfq(externalId, request),
                        "RFQ awarded successfully"));
    }

    /**
     * GET /api/v1/rfqs/{externalId}/award
     * Get the award record for an RFQ.
     */
    @GetMapping("/{externalId}/award")
    public ResponseEntity<ApiResponse<AwardResponse>> getAward(
            @PathVariable String externalId) {
        return ResponseEntity.ok(
                ApiResponse.ok(rfqService.getAwardForRfq(externalId), "Award retrieved"));
    }

    /**
     * POST /api/v1/rfqs/{externalId}/cancel
     * Cancel an RFQ. Publishes erp.vendor.rfq.cancelled
     */
    @PostMapping("/{externalId}/cancel")
    public ResponseEntity<ApiResponse<RfqResponse>> cancelRfq(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String triggeredBy = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes       = body != null ? body.getOrDefault("notes", "") : "";
        return ResponseEntity.ok(
                ApiResponse.ok(rfqService.cancelRfq(externalId, triggeredBy, notes),
                        "RFQ cancelled"));
    }
}
