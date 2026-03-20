package com.enterprise.csprocurement.controller;

import com.enterprise.csprocurement.dto.request.CreateInvoiceRequest;
import com.enterprise.csprocurement.dto.response.ApiResponse;
import com.enterprise.csprocurement.dto.response.InvoiceResponse;
import com.enterprise.csprocurement.service.InvoiceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class InvoiceController {

    private final InvoiceService invoiceService;

    /**
     * POST /api/v1/purchase-orders/{poExternalId}/invoices
     * Receive a vendor invoice against a PO.
     * Publishes erp.procurement.invoice.received
     */
    @PostMapping("/api/v1/purchase-orders/{poExternalId}/invoices")
    public ResponseEntity<ApiResponse<InvoiceResponse>> receiveInvoice(
            @PathVariable String poExternalId,
            @Valid @RequestBody CreateInvoiceRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(
                        invoiceService.receiveInvoice(poExternalId, request),
                        "Invoice received successfully"));
    }

    /**
     * GET /api/v1/purchase-orders/{poExternalId}/invoices
     * List all invoices for a PO.
     */
    @GetMapping("/api/v1/purchase-orders/{poExternalId}/invoices")
    public ResponseEntity<ApiResponse<List<InvoiceResponse>>> getInvoicesForPo(
            @PathVariable String poExternalId) {
        return ResponseEntity.ok(
                ApiResponse.ok(invoiceService.getInvoicesForPo(poExternalId),
                        "Invoices retrieved"));
    }

    /**
     * GET /api/v1/invoices/{invoiceExternalId}
     * Get a single invoice by external ID.
     */
    @GetMapping("/api/v1/invoices/{invoiceExternalId}")
    public ResponseEntity<ApiResponse<InvoiceResponse>> getInvoice(
            @PathVariable String invoiceExternalId) {
        return ResponseEntity.ok(
                ApiResponse.ok(invoiceService.getInvoice(invoiceExternalId),
                        "Invoice retrieved"));
    }

    /**
     * POST /api/v1/invoices/{invoiceExternalId}/approve
     * RECEIVED → APPROVED. Publishes erp.procurement.invoice.approved
     */
    @PostMapping("/api/v1/invoices/{invoiceExternalId}/approve")
    public ResponseEntity<ApiResponse<InvoiceResponse>> approveInvoice(
            @PathVariable String invoiceExternalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("approvedBy", "ap.manager") : "ap.manager";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(invoiceService.approveInvoice(invoiceExternalId, by, notes),
                        "Invoice approved"));
    }

    /**
     * POST /api/v1/invoices/{invoiceExternalId}/pay
     * APPROVED → PAID. Publishes erp.procurement.invoice.paid
     */
    @PostMapping("/api/v1/invoices/{invoiceExternalId}/pay")
    public ResponseEntity<ApiResponse<InvoiceResponse>> payInvoice(
            @PathVariable String invoiceExternalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("paidBy", "treasury") : "treasury";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(
                ApiResponse.ok(invoiceService.payInvoice(invoiceExternalId, by, notes),
                        "Invoice paid"));
    }
}
