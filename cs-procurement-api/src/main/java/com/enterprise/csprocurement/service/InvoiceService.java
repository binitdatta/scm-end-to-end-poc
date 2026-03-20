package com.enterprise.csprocurement.service;

import com.enterprise.csprocurement.dto.request.CreateInvoiceRequest;
import com.enterprise.csprocurement.dto.response.InvoiceResponse;
import com.enterprise.csprocurement.entity.Invoice;
import com.enterprise.csprocurement.entity.PurchaseOrder;
import com.enterprise.csprocurement.exception.DuplicateResourceException;
import com.enterprise.csprocurement.exception.InvalidStateException;
import com.enterprise.csprocurement.exception.ResourceNotFoundException;
import com.enterprise.csprocurement.messaging.ProcurementEventMessage;
import com.enterprise.csprocurement.messaging.ProcurementEventPublisher;
import com.enterprise.csprocurement.repository.InvoiceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InvoiceService {

    private final InvoiceRepository        invoiceRepository;
    private final PurchaseOrderService     poService;
    private final ProcurementEventPublisher publisher;

    // ── RECEIVE INVOICE ───────────────────────────────────────────────────────

    @Transactional
    public InvoiceResponse receiveInvoice(String poExternalId, CreateInvoiceRequest req) {
        PurchaseOrder po = poService.findOrThrow(poExternalId);

        if (invoiceRepository.existsByInvoiceNumber(req.getInvoiceNumber())) {
            throw new DuplicateResourceException(
                    "Invoice number already exists: " + req.getInvoiceNumber());
        }

        BigDecimal tax   = req.getTaxAmountUsd() != null ? req.getTaxAmountUsd() : BigDecimal.ZERO;
        BigDecimal total = req.getInvoiceAmountUsd().add(tax);

        Invoice invoice = Invoice.builder()
                .externalId(UUID.randomUUID().toString())
                .invoiceNumber(req.getInvoiceNumber())
                .purchaseOrder(po)
                .vendorExternalId(po.getVendorExternalId())
                .invoiceAmountUsd(req.getInvoiceAmountUsd())
                .taxAmountUsd(tax)
                .totalAmountUsd(total)
                .invoiceDate(req.getInvoiceDate())
                .dueDate(req.getDueDate())
                .status(Invoice.Status.RECEIVED)
                .notes(req.getNotes())
                .build();

        invoice = invoiceRepository.save(invoice);

        ProcurementEventMessage message = buildInvoiceMessage(
                po, invoice, "INVOICE_RECEIVED", "ap.team", req.getNotes());
        publisher.publishInvoiceReceived(message);

        log.info("Invoice received: invoiceNumber={} po={} total=${}",
                invoice.getInvoiceNumber(), po.getPoNumber(), total);
        return toResponse(invoice, po.getPoNumber());
    }

    // ── APPROVE INVOICE ───────────────────────────────────────────────────────

    @Transactional
    public InvoiceResponse approveInvoice(String invoiceExternalId, String approvedBy, String notes) {
        Invoice invoice = findInvoiceOrThrow(invoiceExternalId);
        PurchaseOrder po = invoice.getPurchaseOrder();

        if (invoice.getStatus() != Invoice.Status.RECEIVED
                && invoice.getStatus() != Invoice.Status.UNDER_REVIEW) {
            throw new InvalidStateException(
                    "Invoice can only be approved from RECEIVED or UNDER_REVIEW. Current: "
                            + invoice.getStatus());
        }

        invoice.setStatus(Invoice.Status.APPROVED);
        invoice = invoiceRepository.save(invoice);

        publisher.publishInvoiceApproved(
                buildInvoiceMessage(po, invoice, "INVOICE_APPROVED", approvedBy, notes));

        log.info("Invoice approved: invoiceNumber={}", invoice.getInvoiceNumber());
        return toResponse(invoice, po.getPoNumber());
    }

    // ── PAY INVOICE ───────────────────────────────────────────────────────────

    @Transactional
    public InvoiceResponse payInvoice(String invoiceExternalId, String paidBy, String notes) {
        Invoice invoice = findInvoiceOrThrow(invoiceExternalId);
        PurchaseOrder po = invoice.getPurchaseOrder();

        if (invoice.getStatus() != Invoice.Status.APPROVED) {
            throw new InvalidStateException(
                    "Invoice must be APPROVED before payment. Current: " + invoice.getStatus());
        }

        invoice.setStatus(Invoice.Status.PAID);
        invoice.setPaidAt(LocalDateTime.now());
        invoice = invoiceRepository.save(invoice);

        publisher.publishInvoicePaid(
                buildInvoiceMessage(po, invoice, "INVOICE_PAID", paidBy, notes));

        log.info("Invoice paid: invoiceNumber={} amount=${}",
                invoice.getInvoiceNumber(), invoice.getTotalAmountUsd());
        return toResponse(invoice, po.getPoNumber());
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<InvoiceResponse> getInvoicesForPo(String poExternalId) {
        PurchaseOrder po = poService.findOrThrow(poExternalId);
        return invoiceRepository.findByPurchaseOrderId(po.getId())
                .stream()
                .map(i -> toResponse(i, po.getPoNumber()))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public InvoiceResponse getInvoice(String invoiceExternalId) {
        Invoice invoice = findInvoiceOrThrow(invoiceExternalId);
        return toResponse(invoice, invoice.getPurchaseOrder().getPoNumber());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    private Invoice findInvoiceOrThrow(String externalId) {
        return invoiceRepository.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Invoice not found: " + externalId));
    }

    private ProcurementEventMessage buildInvoiceMessage(PurchaseOrder po, Invoice invoice,
                                                          String eventType, String triggeredBy,
                                                          String notes) {
        return ProcurementEventMessage.builder()
                .eventType(eventType)
                .poExternalId(po.getExternalId())
                .poNumber(po.getPoNumber())
                .campaignExternalId(po.getCampaignExternalId())
                .campaignCode(po.getCampaignCode())
                .vendorExternalId(po.getVendorExternalId())
                .vendorCode(po.getVendorCode())
                .vendorName(po.getVendorName())
                .vendorCountry(po.getVendorCountry().name())
                .invoiceExternalId(invoice.getExternalId())
                .invoiceNumber(invoice.getInvoiceNumber())
                .invoiceTotalUsd(invoice.getTotalAmountUsd())
                .triggeredBy(triggeredBy)
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    private InvoiceResponse toResponse(Invoice i, String poNumber) {
        return InvoiceResponse.builder()
                .externalId(i.getExternalId())
                .invoiceNumber(i.getInvoiceNumber())
                .poNumber(poNumber)
                .vendorExternalId(i.getVendorExternalId())
                .invoiceAmountUsd(i.getInvoiceAmountUsd())
                .taxAmountUsd(i.getTaxAmountUsd())
                .totalAmountUsd(i.getTotalAmountUsd())
                .invoiceDate(i.getInvoiceDate())
                .dueDate(i.getDueDate())
                .status(i.getStatus().name())
                .paidAt(i.getPaidAt())
                .notes(i.getNotes())
                .createdAt(i.getCreatedAt())
                .build();
    }
}
