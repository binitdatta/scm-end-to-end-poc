package com.enterprise.cswmsinbound.service;

import com.enterprise.cswmsinbound.dto.request.CompletePutawayRequest;
import com.enterprise.cswmsinbound.dto.request.CreateAsnRequest;
import com.enterprise.cswmsinbound.dto.request.ReceiveShipmentRequest;
import com.enterprise.cswmsinbound.dto.response.*;
import com.enterprise.cswmsinbound.entity.*;
import com.enterprise.cswmsinbound.exception.DuplicateResourceException;
import com.enterprise.cswmsinbound.exception.InvalidStateException;
import com.enterprise.cswmsinbound.exception.ResourceNotFoundException;
import com.enterprise.cswmsinbound.messaging.WmsInboundEventMessage;
import com.enterprise.cswmsinbound.messaging.WmsInboundEventPublisher;
import com.enterprise.cswmsinbound.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AsnService {

    private final AsnRepository               asnRepository;
    private final ReceivingRecordRepository   receivingRepo;
    private final PutawayTaskRepository       putawayRepo;
    private final InventoryLocationRepository inventoryRepo;
    private final AsnEventRepository          eventRepo;
    private final WmsInboundEventPublisher    publisher;

    // ── CREATE ASN ────────────────────────────────────────────────────────────

    @Transactional
    public AsnResponse createAsn(CreateAsnRequest req) {
        if (asnRepository.existsByAsnNumber(req.getAsnNumber())) {
            throw new DuplicateResourceException("ASN number already exists: " + req.getAsnNumber());
        }
        if (asnRepository.existsByPoExternalId(req.getPoExternalId())) {
            throw new DuplicateResourceException(
                    "ASN already exists for PO: " + req.getPoExternalId());
        }

        AdvanceShipmentNotice asn = AdvanceShipmentNotice.builder()
                .externalId(UUID.randomUUID().toString())
                .asnNumber(req.getAsnNumber())
                .poExternalId(req.getPoExternalId())
                .poNumber(req.getPoNumber())
                .campaignExternalId(req.getCampaignExternalId())
                .campaignCode(req.getCampaignCode())
                .vendorExternalId(req.getVendorExternalId())
                .vendorCode(req.getVendorCode())
                .vendorName(req.getVendorName())
                .vendorCountry(req.getVendorCountry())
                .sku(req.getSku())
                .toyDescription(req.getToyDescription())
                .expectedQuantity(req.getExpectedQuantity())
                .unitOfMeasure("PIECES")
                .carrierName(req.getCarrierName())
                .trackingNumber(req.getTrackingNumber())
                .originPort(req.getOriginPort())
                .destinationPort(req.getDestinationPort())
                .incoterms(req.getIncoterms())
                .estimatedArrivalDate(req.getEstimatedArrivalDate())
                .dockAppointmentDate(req.getDockAppointmentDate())
                .dockDoor(req.getDockDoor())
                .status(AdvanceShipmentNotice.Status.CREATED)
                .notes(req.getNotes())
                .createdBy(req.getCreatedBy())
                .build();

        asn = asnRepository.save(asn);
        recordEvent(asn, "ASN_CREATED", null, "CREATED", "ASN created", req.getCreatedBy(), false);

        publisher.publishAsnCreated(buildMessage(asn, "ASN_CREATED", req.getCreatedBy(), req.getNotes()));

        log.info("ASN created: asnNumber={} po={}", asn.getAsnNumber(), asn.getPoNumber());
        return toAsnResponse(asn);
    }

    // ── SCHEDULE DOCK ─────────────────────────────────────────────────────────

    @Transactional
    public AsnResponse scheduleDock(String externalId, LocalDateTime appointmentDate,
                                     String dockDoor, String triggeredBy) {
        AdvanceShipmentNotice asn = findOrThrow(externalId);
        requireStatus(asn, AdvanceShipmentNotice.Status.CREATED, "scheduled");

        String prev = asn.getStatus().name();
        asn.setDockAppointmentDate(appointmentDate);
        asn.setDockDoor(dockDoor);
        asn.setStatus(AdvanceShipmentNotice.Status.SCHEDULED);
        asn = asnRepository.save(asn);

        publisher.publishAsnScheduled(buildMessage(asn, "DOCK_SCHEDULED", triggeredBy,
                "Dock " + dockDoor + " at " + appointmentDate));
        recordEvent(asn, "DOCK_SCHEDULED", prev, "SCHEDULED",
                "Dock " + dockDoor + " booked for " + appointmentDate, triggeredBy, true);

        log.info("Dock scheduled: asn={} door={} time={}", asn.getAsnNumber(), dockDoor, appointmentDate);
        return toAsnResponse(asn);
    }

    // ── MARK IN TRANSIT ───────────────────────────────────────────────────────

    @Transactional
    public AsnResponse markInTransit(String externalId, String triggeredBy, String notes) {
        AdvanceShipmentNotice asn = findOrThrow(externalId);
        requireStatus(asn, AdvanceShipmentNotice.Status.SCHEDULED, "marked in transit");

        String prev = asn.getStatus().name();
        asn.setStatus(AdvanceShipmentNotice.Status.IN_TRANSIT);
        asn = asnRepository.save(asn);

        recordEvent(asn, "IN_TRANSIT", prev, "IN_TRANSIT", notes, triggeredBy, false);
        log.info("ASN in transit: asn={}", asn.getAsnNumber());
        return toAsnResponse(asn);
    }

    // ── MARK ARRIVED ──────────────────────────────────────────────────────────

    @Transactional
    public AsnResponse markArrived(String externalId, LocalDate arrivalDate,
                                    String triggeredBy, String notes) {
        AdvanceShipmentNotice asn = findOrThrow(externalId);
        if (asn.getStatus() != AdvanceShipmentNotice.Status.IN_TRANSIT
                && asn.getStatus() != AdvanceShipmentNotice.Status.SCHEDULED) {
            throw new InvalidStateException(
                    "ASN must be IN_TRANSIT or SCHEDULED to mark arrived. Current: " + asn.getStatus());
        }

        String prev = asn.getStatus().name();
        asn.setActualArrivalDate(arrivalDate != null ? arrivalDate : LocalDate.now());
        asn.setStatus(AdvanceShipmentNotice.Status.ARRIVED);
        asn = asnRepository.save(asn);

        publisher.publishShipmentArrived(buildMessage(asn, "SHIPMENT_ARRIVED", triggeredBy, notes));
        recordEvent(asn, "SHIPMENT_ARRIVED", prev, "ARRIVED", notes, triggeredBy, true);

        log.info("Shipment arrived: asn={} arrivalDate={}", asn.getAsnNumber(), asn.getActualArrivalDate());
        return toAsnResponse(asn);
    }

    // ── RECEIVE SHIPMENT ──────────────────────────────────────────────────────

    @Transactional
    public ReceivingResponse receiveShipment(String externalId, ReceiveShipmentRequest req) {
        AdvanceShipmentNotice asn = findOrThrow(externalId);

        if (asn.getStatus() != AdvanceShipmentNotice.Status.ARRIVED) {
            throw new InvalidStateException(
                    "ASN must be ARRIVED to receive. Current: " + asn.getStatus());
        }
        if (receivingRepo.existsByAsnId(asn.getId())) {
            throw new DuplicateResourceException("Receiving already recorded for ASN: " + asn.getAsnNumber());
        }

        int damaged   = req.getDamagedQuantity()  != null ? req.getDamagedQuantity()  : 0;
        int rejected  = req.getRejectedQuantity()  != null ? req.getRejectedQuantity()  : 0;
        int accepted  = req.getReceivedQuantity() - damaged - rejected;
        int variance  = req.getReceivedQuantity() - asn.getExpectedQuantity();
        boolean qc    = req.getQcPassed() != null ? req.getQcPassed() : (damaged == 0 && rejected == 0);

        ReceivingRecord record = ReceivingRecord.builder()
                .externalId(UUID.randomUUID().toString())
                .asn(asn)
                .receivedQuantity(req.getReceivedQuantity())
                .damagedQuantity(damaged)
                .rejectedQuantity(rejected)
                .acceptedQuantity(accepted)
                .varianceQuantity(variance)
                .receivedBy(req.getReceivedBy())
                .receivedAt(LocalDateTime.now())
                .qcPassed(qc)
                .qcNotes(req.getQcNotes())
                .build();

        receivingRepo.save(record);

        String prev = asn.getStatus().name();
        asn.setStatus(AdvanceShipmentNotice.Status.RECEIVED);
        asnRepository.save(asn);

        publisher.publishReceivingCompleted(
                buildMessageWithReceiving(asn, record, "RECEIVING_COMPLETED", req.getReceivedBy()));
        recordEvent(asn, "RECEIVING_COMPLETED", prev, "RECEIVED",
                "Accepted=" + accepted + " Damaged=" + damaged + " Variance=" + variance,
                req.getReceivedBy(), true);

        log.info("Receiving complete: asn={} accepted={} variance={}",
                asn.getAsnNumber(), accepted, variance);
        return toReceivingResponse(record, asn.getAsnNumber());
    }

    // ── COMPLETE PUTAWAY ──────────────────────────────────────────────────────

    @Transactional
    public PutawayResponse completePutaway(String externalId, CompletePutawayRequest req) {
        AdvanceShipmentNotice asn = findOrThrow(externalId);

        if (asn.getStatus() != AdvanceShipmentNotice.Status.RECEIVED
                && asn.getStatus() != AdvanceShipmentNotice.Status.PUTAWAY_IN_PROGRESS) {
            throw new InvalidStateException(
                    "ASN must be RECEIVED or PUTAWAY_IN_PROGRESS to complete putaway. Current: "
                            + asn.getStatus());
        }

        ReceivingRecord record = receivingRepo.findByAsnId(asn.getId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No receiving record for ASN: " + asn.getAsnNumber()));

        List<PutawayTask> tasks     = new ArrayList<>();
        List<WmsInboundEventMessage.BinLocation> binLocations = new ArrayList<>();
        int totalPutaway = 0;

        for (CompletePutawayRequest.BinAllocation alloc : req.getBinAllocations()) {
            PutawayTask task = PutawayTask.builder()
                    .externalId(UUID.randomUUID().toString())
                    .asn(asn)
                    .sku(asn.getSku())
                    .quantityToPutaway(alloc.getQuantity())
                    .quantityPutaway(alloc.getQuantity())
                    .warehouseZone(alloc.getWarehouseZone())
                    .warehouseAisle(alloc.getWarehouseAisle())
                    .warehouseBin(alloc.getWarehouseBin())
                    .status(PutawayTask.Status.COMPLETED)
                    .assignedTo(req.getCompletedBy())
                    .startedAt(LocalDateTime.now())
                    .completedAt(LocalDateTime.now())
                    .build();

            putawayRepo.save(task);
            tasks.add(task);
            totalPutaway += alloc.getQuantity();

            // Upsert inventory location
            InventoryLocation loc = inventoryRepo
                    .findBySkuAndWarehouseBin(asn.getSku(), alloc.getWarehouseBin())
                    .orElse(InventoryLocation.builder()
                            .sku(asn.getSku())
                            .campaignCode(asn.getCampaignCode())
                            .warehouseZone(alloc.getWarehouseZone())
                            .warehouseAisle(alloc.getWarehouseAisle())
                            .warehouseBin(alloc.getWarehouseBin())
                            .quantityOnHand(0)
                            .quantityReserved(0)
                            .quantityAvailable(0)
                            .build());

            loc.setQuantityOnHand(loc.getQuantityOnHand() + alloc.getQuantity());
            loc.setQuantityAvailable(loc.getQuantityOnHand() - loc.getQuantityReserved());
            loc.setLastReceiptDate(LocalDate.now());
            inventoryRepo.save(loc);

            binLocations.add(WmsInboundEventMessage.BinLocation.builder()
                    .warehouseZone(alloc.getWarehouseZone())
                    .warehouseAisle(alloc.getWarehouseAisle())
                    .warehouseBin(alloc.getWarehouseBin())
                    .quantity(alloc.getQuantity())
                    .build());
        }

        String prev = asn.getStatus().name();
        asn.setStatus(AdvanceShipmentNotice.Status.PUTAWAY_COMPLETED);
        asnRepository.save(asn);

        // Build the KEY event consumed by cs-oms-api
        WmsInboundEventMessage message = buildMessage(asn, "PUTAWAY_COMPLETED",
                req.getCompletedBy(), req.getNotes());
        message.setAcceptedQuantity(record.getAcceptedQuantity());
        message.setDamagedQuantity(record.getDamagedQuantity());
        message.setVarianceQuantity(record.getVarianceQuantity());
        message.setBinLocations(binLocations);
        publisher.publishPutawayCompleted(message);

        recordEvent(asn, "PUTAWAY_COMPLETED", prev, "PUTAWAY_COMPLETED",
                "Total putaway=" + totalPutaway + " across " + tasks.size() + " bins",
                req.getCompletedBy(), true);

        log.info("Putaway complete: asn={} sku={} totalPutaway={} bins={}",
                asn.getAsnNumber(), asn.getSku(), totalPutaway, tasks.size());

        return PutawayResponse.builder()
                .asnNumber(asn.getAsnNumber())
                .campaignCode(asn.getCampaignCode())
                .sku(asn.getSku())
                .totalQuantityPutaway(totalPutaway)
                .completedAt(LocalDateTime.now())
                .bins(tasks.stream().map(t -> PutawayResponse.BinDetail.builder()
                        .warehouseZone(t.getWarehouseZone())
                        .warehouseAisle(t.getWarehouseAisle())
                        .warehouseBin(t.getWarehouseBin())
                        .quantity(t.getQuantityPutaway())
                        .build()).collect(Collectors.toList()))
                .build();
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public AsnResponse getAsn(String externalId) {
        return toAsnResponse(findOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<AsnResponse> getAllAsns() {
        return asnRepository.findAll().stream().map(this::toAsnResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AsnResponse> getAsnsByStatus(String status) {
        return asnRepository.findByStatus(AdvanceShipmentNotice.Status.valueOf(status))
                .stream().map(this::toAsnResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ReceivingResponse getReceivingRecord(String externalId) {
        AdvanceShipmentNotice asn = findOrThrow(externalId);
        ReceivingRecord record = receivingRepo.findByAsnId(asn.getId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No receiving record for ASN: " + externalId));
        return toReceivingResponse(record, asn.getAsnNumber());
    }

    @Transactional(readOnly = true)
    public List<AsnEventResponse> getAsnEvents(String externalId) {
        AdvanceShipmentNotice asn = findOrThrow(externalId);
        return eventRepo.findByAsnIdOrderByEventAtDesc(asn.getId())
                .stream().map(this::toEventResponse).collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    public AdvanceShipmentNotice findOrThrow(String externalId) {
        return asnRepository.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException("ASN not found: " + externalId));
    }

    private void requireStatus(AdvanceShipmentNotice asn,
                                AdvanceShipmentNotice.Status required, String action) {
        if (asn.getStatus() != required) {
            throw new InvalidStateException(
                    "ASN must be " + required.name() + " to be " + action
                            + ". Current: " + asn.getStatus());
        }
    }

    private void recordEvent(AdvanceShipmentNotice asn, String type, String prev, String next,
                              String notes, String by, boolean published) {
        eventRepo.save(AsnEvent.builder()
                .asn(asn).eventType(type).previousStatus(prev).newStatus(next)
                .notes(notes).triggeredBy(by).eventAt(LocalDateTime.now())
                .rabbitmqPublished(published).build());
    }

    private WmsInboundEventMessage buildMessage(AdvanceShipmentNotice asn,
                                                  String eventType, String triggeredBy, String notes) {
        return WmsInboundEventMessage.builder()
                .eventType(eventType)
                .asnExternalId(asn.getExternalId())
                .asnNumber(asn.getAsnNumber())
                .asnStatus(asn.getStatus().name())
                .poExternalId(asn.getPoExternalId())
                .poNumber(asn.getPoNumber())
                .campaignExternalId(asn.getCampaignExternalId())
                .campaignCode(asn.getCampaignCode())
                .vendorExternalId(asn.getVendorExternalId())
                .vendorCode(asn.getVendorCode())
                .vendorName(asn.getVendorName())
                .sku(asn.getSku())
                .toyDescription(asn.getToyDescription())
                .expectedQuantity(asn.getExpectedQuantity())
                .carrierName(asn.getCarrierName())
                .trackingNumber(asn.getTrackingNumber())
                .destinationPort(asn.getDestinationPort())
                .actualArrivalDate(asn.getActualArrivalDate())
                .triggeredBy(triggeredBy)
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    private WmsInboundEventMessage buildMessageWithReceiving(AdvanceShipmentNotice asn,
                                                               ReceivingRecord rec,
                                                               String eventType, String triggeredBy) {
        WmsInboundEventMessage msg = buildMessage(asn, eventType, triggeredBy, rec.getQcNotes());
        msg.setAcceptedQuantity(rec.getAcceptedQuantity());
        msg.setDamagedQuantity(rec.getDamagedQuantity());
        msg.setVarianceQuantity(rec.getVarianceQuantity());
        return msg;
    }

    public AsnResponse toAsnResponse(AdvanceShipmentNotice a) {
        return AsnResponse.builder()
                .externalId(a.getExternalId())
                .asnNumber(a.getAsnNumber())
                .poExternalId(a.getPoExternalId())
                .poNumber(a.getPoNumber())
                .campaignExternalId(a.getCampaignExternalId())
                .campaignCode(a.getCampaignCode())
                .vendorExternalId(a.getVendorExternalId())
                .vendorCode(a.getVendorCode())
                .vendorName(a.getVendorName())
                .vendorCountry(a.getVendorCountry())
                .sku(a.getSku())
                .toyDescription(a.getToyDescription())
                .expectedQuantity(a.getExpectedQuantity())
                .unitOfMeasure(a.getUnitOfMeasure())
                .carrierName(a.getCarrierName())
                .trackingNumber(a.getTrackingNumber())
                .originPort(a.getOriginPort())
                .destinationPort(a.getDestinationPort())
                .incoterms(a.getIncoterms())
                .estimatedArrivalDate(a.getEstimatedArrivalDate())
                .actualArrivalDate(a.getActualArrivalDate())
                .dockAppointmentDate(a.getDockAppointmentDate())
                .dockDoor(a.getDockDoor())
                .status(a.getStatus().name())
                .notes(a.getNotes())
                .createdBy(a.getCreatedBy())
                .createdAt(a.getCreatedAt())
                .updatedAt(a.getUpdatedAt())
                .build();
    }

    private ReceivingResponse toReceivingResponse(ReceivingRecord r, String asnNumber) {
        return ReceivingResponse.builder()
                .externalId(r.getExternalId())
                .asnNumber(asnNumber)
                .receivedQuantity(r.getReceivedQuantity())
                .damagedQuantity(r.getDamagedQuantity())
                .rejectedQuantity(r.getRejectedQuantity())
                .acceptedQuantity(r.getAcceptedQuantity())
                .varianceQuantity(r.getVarianceQuantity())
                .receivedBy(r.getReceivedBy())
                .qcPassed(r.isQcPassed())
                .qcNotes(r.getQcNotes())
                .receivedAt(r.getReceivedAt())
                .build();
    }

    private AsnEventResponse toEventResponse(AsnEvent e) {
        return AsnEventResponse.builder()
                .id(e.getId()).eventType(e.getEventType())
                .previousStatus(e.getPreviousStatus()).newStatus(e.getNewStatus())
                .notes(e.getNotes()).triggeredBy(e.getTriggeredBy())
                .rabbitmqPublished(e.isRabbitmqPublished()).eventAt(e.getEventAt())
                .build();
    }
}
