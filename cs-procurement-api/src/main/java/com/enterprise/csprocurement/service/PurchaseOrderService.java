package com.enterprise.csprocurement.service;

import com.enterprise.csprocurement.dto.request.ApprovePoRequest;
import com.enterprise.csprocurement.dto.request.CreatePoRequest;
import com.enterprise.csprocurement.dto.response.PoEventResponse;
import com.enterprise.csprocurement.dto.response.PoResponse;
import com.enterprise.csprocurement.entity.PoEvent;
import com.enterprise.csprocurement.entity.PoLineItem;
import com.enterprise.csprocurement.entity.PurchaseOrder;
import com.enterprise.csprocurement.exception.DuplicateResourceException;
import com.enterprise.csprocurement.exception.InvalidStateException;
import com.enterprise.csprocurement.exception.ResourceNotFoundException;
import com.enterprise.csprocurement.messaging.ProcurementEventMessage;
import com.enterprise.csprocurement.messaging.ProcurementEventPublisher;
import com.enterprise.csprocurement.repository.PoEventRepository;
import com.enterprise.csprocurement.repository.PurchaseOrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PurchaseOrderService {

    private final PurchaseOrderRepository poRepository;
    private final PoEventRepository       poEventRepository;
    private final ProcurementEventPublisher publisher;

    // ── CREATE ────────────────────────────────────────────────────────────────

    @Transactional
    public PoResponse createPo(CreatePoRequest req) {
        if (poRepository.existsByPoNumber(req.getPoNumber())) {
            throw new DuplicateResourceException("PO number already exists: " + req.getPoNumber());
        }
        if (poRepository.existsByAwardExternalId(req.getAwardExternalId())) {
            throw new DuplicateResourceException(
                    "A PO already exists for award: " + req.getAwardExternalId());
        }

        BigDecimal total = req.getUnitPriceUsd()
                .multiply(BigDecimal.valueOf(req.getQuantityOrdered()))
                .setScale(2, RoundingMode.HALF_UP);

        PurchaseOrder po = PurchaseOrder.builder()
                .externalId(UUID.randomUUID().toString())
                .poNumber(req.getPoNumber())
                .rfqExternalId(req.getRfqExternalId())
                .rfqNumber(req.getRfqNumber())
                .campaignExternalId(req.getCampaignExternalId())
                .campaignCode(req.getCampaignCode())
                .awardExternalId(req.getAwardExternalId())
                .vendorExternalId(req.getVendorExternalId())
                .vendorCode(req.getVendorCode())
                .vendorName(req.getVendorName())
                .vendorCountry(PurchaseOrder.VendorCountry.valueOf(req.getVendorCountry()))
                .toyDescription(req.getToyDescription())
                .quantityOrdered(req.getQuantityOrdered())
                .unitPriceUsd(req.getUnitPriceUsd())
                .totalValueUsd(total)
                .currency("USD")
                .paymentTerms(req.getPaymentTerms())
                .requiredDeliveryDate(req.getRequiredDeliveryDate())
                .estimatedShipDate(req.getEstimatedShipDate())
                .incoterms(req.getIncoterms())
                .destinationPort(req.getDestinationPort())
                .status(PurchaseOrder.Status.DRAFT)
                .createdBy(req.getCreatedBy())
                .notes(req.getNotes())
                .build();

        // Add line items if provided
        if (req.getLineItems() != null && !req.getLineItems().isEmpty()) {
            int lineNum = 1;
            for (CreatePoRequest.LineItemRequest li : req.getLineItems()) {
                BigDecimal lineTotal = li.getUnitPriceUsd()
                        .multiply(BigDecimal.valueOf(li.getQuantity()))
                        .setScale(2, RoundingMode.HALF_UP);
                PoLineItem item = PoLineItem.builder()
                        .externalId(UUID.randomUUID().toString())
                        .purchaseOrder(po)
                        .lineNumber(lineNum++)
                        .itemCode(li.getItemCode())
                        .description(li.getDescription())
                        .quantity(li.getQuantity())
                        .unit("PIECES")
                        .unitPriceUsd(li.getUnitPriceUsd())
                        .lineTotalUsd(lineTotal)
                        .build();
                po.getLineItems().add(item);
            }
        }

        po = poRepository.save(po);
        recordEvent(po, "CREATED", null, "DRAFT", "PO created", req.getCreatedBy(), false);

        publisher.publishPoCreated(buildMessage(po, "PO_CREATED", req.getCreatedBy(), req.getNotes()));

        log.info("PO created: poNumber={} vendor={} total=${}", po.getPoNumber(), po.getVendorCode(), total);
        return toResponse(po);
    }

    // ── APPROVE ───────────────────────────────────────────────────────────────

    @Transactional
    public PoResponse approvePo(String externalId, ApprovePoRequest req) {
        PurchaseOrder po = findOrThrow(externalId);
        requireStatus(po, PurchaseOrder.Status.DRAFT, "approved");

        String prev = po.getStatus().name();
        po.setStatus(PurchaseOrder.Status.APPROVED);
        po.setApprovedBy(req.getApprovedBy());
        po.setApprovedAt(LocalDateTime.now());
        po = poRepository.save(po);

        publisher.publishPoApproved(buildMessage(po, "PO_APPROVED", req.getApprovedBy(), req.getNotes()));
        recordEvent(po, "APPROVED", prev, "APPROVED", req.getNotes(), req.getApprovedBy(), true);

        log.info("PO approved: poNumber={} by={}", po.getPoNumber(), req.getApprovedBy());
        return toResponse(po);
    }

    // ── SEND TO VENDOR ────────────────────────────────────────────────────────

    @Transactional
    public PoResponse sendToVendor(String externalId, String triggeredBy, String notes) {
        PurchaseOrder po = findOrThrow(externalId);
        requireStatus(po, PurchaseOrder.Status.APPROVED, "sent to vendor");

        String prev = po.getStatus().name();
        po.setStatus(PurchaseOrder.Status.SENT_TO_VENDOR);
        po = poRepository.save(po);

        publisher.publishPoSent(buildMessage(po, "PO_SENT_TO_VENDOR", triggeredBy, notes));
        recordEvent(po, "SENT_TO_VENDOR", prev, "SENT_TO_VENDOR", notes, triggeredBy, true);

        log.info("PO sent to vendor: poNumber={}", po.getPoNumber());
        return toResponse(po);
    }

    // ── ACKNOWLEDGE ───────────────────────────────────────────────────────────

    @Transactional
    public PoResponse acknowledgePo(String externalId, String triggeredBy, String notes) {
        PurchaseOrder po = findOrThrow(externalId);
        requireStatus(po, PurchaseOrder.Status.SENT_TO_VENDOR, "acknowledged");

        String prev = po.getStatus().name();
        po.setStatus(PurchaseOrder.Status.ACKNOWLEDGED);
        po = poRepository.save(po);

        publisher.publishPoAcknowledged(buildMessage(po, "PO_ACKNOWLEDGED", triggeredBy, notes));
        recordEvent(po, "ACKNOWLEDGED", prev, "ACKNOWLEDGED", notes, triggeredBy, true);

        log.info("PO acknowledged by vendor: poNumber={}", po.getPoNumber());
        return toResponse(po);
    }

    // ── IN PRODUCTION ─────────────────────────────────────────────────────────

    @Transactional
    public PoResponse markInProduction(String externalId, String triggeredBy, String notes) {
        PurchaseOrder po = findOrThrow(externalId);
        requireStatus(po, PurchaseOrder.Status.ACKNOWLEDGED, "in production");

        String prev = po.getStatus().name();
        po.setStatus(PurchaseOrder.Status.IN_PRODUCTION);
        po = poRepository.save(po);

        publisher.publishPoInProduction(buildMessage(po, "PO_IN_PRODUCTION", triggeredBy, notes));
        recordEvent(po, "IN_PRODUCTION", prev, "IN_PRODUCTION", notes, triggeredBy, true);

        log.info("PO in production: poNumber={}", po.getPoNumber());
        return toResponse(po);
    }

    // ── READY TO SHIP ─────────────────────────────────────────────────────────
    // KEY event — WMS Inbound subscribes to this to create an ASN

    @Transactional
    public PoResponse markReadyToShip(String externalId, String triggeredBy,
                                       String notes, java.time.LocalDate shipDate) {
        PurchaseOrder po = findOrThrow(externalId);
        requireStatus(po, PurchaseOrder.Status.IN_PRODUCTION, "ready to ship");

        String prev = po.getStatus().name();
        if (shipDate != null) po.setEstimatedShipDate(shipDate);
        po.setStatus(PurchaseOrder.Status.READY_TO_SHIP);
        po = poRepository.save(po);

        publisher.publishPoReadyToShip(buildMessage(po, "PO_READY_TO_SHIP", triggeredBy, notes));
        recordEvent(po, "READY_TO_SHIP", prev, "READY_TO_SHIP", notes, triggeredBy, true);

        log.info("PO ready to ship: poNumber={} shipDate={}", po.getPoNumber(), po.getEstimatedShipDate());
        return toResponse(po);
    }

    // ── COMPLETE ──────────────────────────────────────────────────────────────

    @Transactional
    public PoResponse completePo(String externalId, String triggeredBy, String notes) {
        PurchaseOrder po = findOrThrow(externalId);
        if (po.getStatus() != PurchaseOrder.Status.READY_TO_SHIP
                && po.getStatus() != PurchaseOrder.Status.ACKNOWLEDGED) {
            throw new InvalidStateException(
                    "PO can only be completed from READY_TO_SHIP or ACKNOWLEDGED. Current: "
                            + po.getStatus());
        }

        String prev = po.getStatus().name();
        po.setStatus(PurchaseOrder.Status.COMPLETED);
        po = poRepository.save(po);

        publisher.publishPoCompleted(buildMessage(po, "PO_COMPLETED", triggeredBy, notes));
        recordEvent(po, "COMPLETED", prev, "COMPLETED", notes, triggeredBy, true);

        log.info("PO completed: poNumber={}", po.getPoNumber());
        return toResponse(po);
    }

    // ── CANCEL ────────────────────────────────────────────────────────────────

    @Transactional
    public PoResponse cancelPo(String externalId, String triggeredBy, String notes) {
        PurchaseOrder po = findOrThrow(externalId);
        if (po.getStatus() == PurchaseOrder.Status.COMPLETED
                || po.getStatus() == PurchaseOrder.Status.CANCELLED) {
            throw new InvalidStateException(
                    "Cannot cancel a COMPLETED or already CANCELLED PO. Current: " + po.getStatus());
        }

        String prev = po.getStatus().name();
        po.setStatus(PurchaseOrder.Status.CANCELLED);
        po = poRepository.save(po);

        publisher.publishPoCancelled(buildMessage(po, "PO_CANCELLED", triggeredBy, notes));
        recordEvent(po, "CANCELLED", prev, "CANCELLED", notes, triggeredBy, true);

        log.info("PO cancelled: poNumber={}", po.getPoNumber());
        return toResponse(po);
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PoResponse getPo(String externalId) {
        return toResponse(findOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<PoResponse> getAllPos() {
        return poRepository.findAll().stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PoResponse> getPosByStatus(String status) {
        return poRepository.findByStatus(PurchaseOrder.Status.valueOf(status))
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PoEventResponse> getPoEvents(String externalId) {
        PurchaseOrder po = findOrThrow(externalId);
        return poEventRepository.findByPurchaseOrderIdOrderByEventAtDesc(po.getId())
                .stream().map(this::toEventResponse).collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    public PurchaseOrder findOrThrow(String externalId) {
        return poRepository.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException("PO not found: " + externalId));
    }

    private void requireStatus(PurchaseOrder po, PurchaseOrder.Status required, String action) {
        if (po.getStatus() != required) {
            throw new InvalidStateException(
                    "PO must be " + required.name() + " to be " + action
                            + ". Current: " + po.getStatus());
        }
    }

    private void recordEvent(PurchaseOrder po, String type, String prev, String next,
                              String notes, String by, boolean published) {
        PoEvent event = PoEvent.builder()
                .purchaseOrder(po)
                .eventType(type)
                .previousStatus(prev)
                .newStatus(next)
                .notes(notes)
                .triggeredBy(by)
                .eventAt(LocalDateTime.now())
                .rabbitmqPublished(published)
                .build();
        poEventRepository.save(event);
    }

    private ProcurementEventMessage buildMessage(PurchaseOrder po, String eventType,
                                                   String triggeredBy, String notes) {
        return ProcurementEventMessage.builder()
                .eventType(eventType)
                .poExternalId(po.getExternalId())
                .poNumber(po.getPoNumber())
                .rfqExternalId(po.getRfqExternalId())
                .rfqNumber(po.getRfqNumber())
                .campaignExternalId(po.getCampaignExternalId())
                .campaignCode(po.getCampaignCode())
                .poStatus(po.getStatus().name())
                .vendorExternalId(po.getVendorExternalId())
                .vendorCode(po.getVendorCode())
                .vendorName(po.getVendorName())
                .vendorCountry(po.getVendorCountry().name())
                .toyDescription(po.getToyDescription())
                .quantityOrdered(po.getQuantityOrdered())
                .unitPriceUsd(po.getUnitPriceUsd())
                .totalValueUsd(po.getTotalValueUsd())
                .paymentTerms(po.getPaymentTerms())
                .incoterms(po.getIncoterms())
                .destinationPort(po.getDestinationPort())
                .requiredDeliveryDate(po.getRequiredDeliveryDate())
                .estimatedShipDate(po.getEstimatedShipDate())
                .triggeredBy(triggeredBy)
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    public PoResponse toResponse(PurchaseOrder po) {
        List<PoResponse.LineItemResponse> items = po.getLineItems().stream()
                .map(li -> PoResponse.LineItemResponse.builder()
                        .externalId(li.getExternalId())
                        .lineNumber(li.getLineNumber())
                        .itemCode(li.getItemCode())
                        .description(li.getDescription())
                        .quantity(li.getQuantity())
                        .unit(li.getUnit())
                        .unitPriceUsd(li.getUnitPriceUsd())
                        .lineTotalUsd(li.getLineTotalUsd())
                        .build())
                .collect(Collectors.toList());

        return PoResponse.builder()
                .externalId(po.getExternalId())
                .poNumber(po.getPoNumber())
                .rfqExternalId(po.getRfqExternalId())
                .rfqNumber(po.getRfqNumber())
                .campaignExternalId(po.getCampaignExternalId())
                .campaignCode(po.getCampaignCode())
                .awardExternalId(po.getAwardExternalId())
                .vendorExternalId(po.getVendorExternalId())
                .vendorCode(po.getVendorCode())
                .vendorName(po.getVendorName())
                .vendorCountry(po.getVendorCountry().name())
                .toyDescription(po.getToyDescription())
                .quantityOrdered(po.getQuantityOrdered())
                .unitPriceUsd(po.getUnitPriceUsd())
                .totalValueUsd(po.getTotalValueUsd())
                .currency(po.getCurrency())
                .paymentTerms(po.getPaymentTerms())
                .incoterms(po.getIncoterms())
                .destinationPort(po.getDestinationPort())
                .requiredDeliveryDate(po.getRequiredDeliveryDate())
                .estimatedShipDate(po.getEstimatedShipDate())
                .status(po.getStatus().name())
                .createdBy(po.getCreatedBy())
                .approvedBy(po.getApprovedBy())
                .approvedAt(po.getApprovedAt())
                .notes(po.getNotes())
                .createdAt(po.getCreatedAt())
                .updatedAt(po.getUpdatedAt())
                .lineItems(items)
                .build();
    }

    private PoEventResponse toEventResponse(PoEvent e) {
        return PoEventResponse.builder()
                .id(e.getId())
                .eventType(e.getEventType())
                .previousStatus(e.getPreviousStatus())
                .newStatus(e.getNewStatus())
                .notes(e.getNotes())
                .triggeredBy(e.getTriggeredBy())
                .rabbitmqPublished(e.isRabbitmqPublished())
                .eventAt(e.getEventAt())
                .build();
    }
}
