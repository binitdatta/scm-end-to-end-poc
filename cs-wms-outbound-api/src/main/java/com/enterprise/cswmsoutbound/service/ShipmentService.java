package com.enterprise.cswmsoutbound.service;

import com.enterprise.cswmsoutbound.dto.request.CreateShipmentRequest;
import com.enterprise.cswmsoutbound.dto.request.ManifestShipmentRequest;
import com.enterprise.cswmsoutbound.dto.response.OutboundEventResponse;
import com.enterprise.cswmsoutbound.dto.response.ShipmentResponse;
import com.enterprise.cswmsoutbound.entity.*;
import com.enterprise.cswmsoutbound.exception.*;
import com.enterprise.cswmsoutbound.messaging.WmsOutboundEventMessage;
import com.enterprise.cswmsoutbound.messaging.WmsOutboundEventPublisher;
import com.enterprise.cswmsoutbound.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ShipmentService {

    private final OutboundShipmentRepository  shipmentRepo;
    private final ShipmentStoreLineRepository storeLineRepo;
    private final OutboundEventRepository     eventRepo;
    private final PickWaveService             waveService;
    private final WmsOutboundEventPublisher   publisher;

    // ── CREATE SHIPMENT (from completed pick wave) ────────────────────────────

    @Transactional
    public ShipmentResponse createShipment(CreateShipmentRequest req) {
        if (shipmentRepo.existsByShipmentNumber(req.getShipmentNumber())) {
            throw new DuplicateResourceException(
                    "Shipment number already exists: " + req.getShipmentNumber());
        }

        PickWave wave = waveService.findWaveOrThrow(req.getPickWaveExternalId());

        if (wave.getStatus() != PickWave.Status.COMPLETED) {
            throw new InvalidStateException(
                    "Pick wave must be COMPLETED before creating shipment. Current: "
                            + wave.getStatus());
        }

        int totalCartons = req.getStoreCartons().size();
        int totalUnits   = req.getStoreCartons().stream()
                .mapToInt(CreateShipmentRequest.StoreCartonRequest::getQuantity).sum();

        OutboundShipment shipment = OutboundShipment.builder()
                .externalId(UUID.randomUUID().toString())
                .shipmentNumber(req.getShipmentNumber())
                .pickWave(wave)
                .storeOrderExternalId(wave.getStoreOrderExternalId())
                .storeOrderNumber(wave.getStoreOrderNumber())
                .campaignExternalId(wave.getCampaignExternalId())
                .campaignCode(wave.getCampaignCode())
                .regionCode(wave.getRegionCode())
                .distributionDc(req.getDistributionDc())
                .sku(wave.getSku())
                .toyDescription(wave.getToyDescription())
                .totalCartons(totalCartons)
                .totalUnits(totalUnits)
                .unitsPerCarton(totalCartons > 0 ? totalUnits / totalCartons : 0)
                .carrierName(req.getCarrierName())
                .requiredDeliveryDate(req.getRequiredDeliveryDate())
                .estimatedShipDate(req.getEstimatedShipDate())
                .status(OutboundShipment.Status.CREATED)
                .notes(req.getNotes())
                .createdBy(req.getCreatedBy())
                .build();

        shipment = shipmentRepo.save(shipment);

        // Create per-store carton lines
        for (CreateShipmentRequest.StoreCartonRequest sc : req.getStoreCartons()) {
            ShipmentStoreLine line = ShipmentStoreLine.builder()
                    .externalId(UUID.randomUUID().toString())
                    .shipment(shipment)
                    .storeExternalId(sc.getStoreExternalId())
                    .storeNumber(sc.getStoreNumber())
                    .storeName(sc.getStoreName())
                    .city(sc.getCity())
                    .stateCode(sc.getStateCode())
                    .sku(sc.getSku())
                    .quantity(sc.getQuantity())
                    .cartonLabel(sc.getCartonLabel() != null
                            ? sc.getCartonLabel()
                            : "CTN-" + sc.getStoreNumber() + "-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase())
                    .status(ShipmentStoreLine.Status.PENDING)
                    .build();
            storeLineRepo.save(line);
        }

        waveService.recordEvent("SHIPMENT", shipment.getId(), "SHIPMENT_CREATED",
                null, "CREATED", "Shipment created from wave " + wave.getWaveNumber(),
                req.getCreatedBy(), false);

        publisher.publishShipmentCreated(buildShipmentMessage(shipment, wave,
                "SHIPMENT_CREATED", req.getCreatedBy(), req.getNotes(), null));

        log.info("Shipment created: shipmentNumber={} cartons={} units={}",
                shipment.getShipmentNumber(), totalCartons, totalUnits);
        return toResponse(shipment);
    }

    // ── PACK ──────────────────────────────────────────────────────────────────

    @Transactional
    public ShipmentResponse packShipment(String externalId, String triggeredBy, String notes) {
        OutboundShipment shipment = findOrThrow(externalId);
        requireStatus(shipment, OutboundShipment.Status.CREATED, "packed");

        String prev = shipment.getStatus().name();
        shipment.setStatus(OutboundShipment.Status.PACKED);

        // Update all store lines to PACKED
        storeLineRepo.findByShipmentId(shipment.getId()).forEach(l -> {
            l.setStatus(ShipmentStoreLine.Status.PACKED);
            storeLineRepo.save(l);
        });

        final OutboundShipment saved = shipmentRepo.save(shipment);

        publisher.publishShipmentPacked(buildShipmentMessage(saved, saved.getPickWave(),
                "SHIPMENT_PACKED", triggeredBy, notes, null));
        waveService.recordEvent("SHIPMENT", saved.getId(), "SHIPMENT_PACKED",
                prev, "PACKED", notes, triggeredBy, true);

        log.info("Shipment packed: shipmentNumber={}", saved.getShipmentNumber());
        return toResponse(saved);
    }

    // ── MANIFEST ──────────────────────────────────────────────────────────────

    @Transactional
    public ShipmentResponse manifestShipment(String externalId, ManifestShipmentRequest req) {
        OutboundShipment shipment = findOrThrow(externalId);
        requireStatus(shipment, OutboundShipment.Status.PACKED, "manifested");

        String prev = shipment.getStatus().name();
        shipment.setCarrierName(req.getCarrierName());
        shipment.setProNumber(req.getProNumber());
        shipment.setStatus(OutboundShipment.Status.MANIFESTED);
        final OutboundShipment saved = shipmentRepo.save(shipment);

        publisher.publishShipmentManifested(buildShipmentMessage(saved, saved.getPickWave(),
                "SHIPMENT_MANIFESTED", "wms.outbound.coordinator", req.getNotes(), null));
        waveService.recordEvent("SHIPMENT", saved.getId(), "SHIPMENT_MANIFESTED",
                prev, "MANIFESTED",
                "Carrier: " + req.getCarrierName() + " PRO: " + req.getProNumber(),
                "wms.outbound.coordinator", true);

        log.info("Shipment manifested: shipmentNumber={} carrier={} pro={}",
                saved.getShipmentNumber(), req.getCarrierName(), req.getProNumber());
        return toResponse(saved);
    }

    // ── DISPATCH — KEY EVENT ──────────────────────────────────────────────────

    @Transactional
    public ShipmentResponse dispatchShipment(String externalId, String triggeredBy, String notes) {
        OutboundShipment shipment = findOrThrow(externalId);
        requireStatus(shipment, OutboundShipment.Status.MANIFESTED, "dispatched");

        String prev = shipment.getStatus().name();
        shipment.setActualShipDate(LocalDate.now());
        shipment.setStatus(OutboundShipment.Status.DISPATCHED);

        // Update all store lines to DISPATCHED
        storeLineRepo.findByShipmentId(shipment.getId()).forEach(l -> {
            l.setStatus(ShipmentStoreLine.Status.DISPATCHED);
            storeLineRepo.save(l);
        });

        final OutboundShipment saved = shipmentRepo.save(shipment);

        // Build KEY event payload with full store carton list
        List<WmsOutboundEventMessage.StoreCarton> cartons =
                storeLineRepo.findByShipmentId(saved.getId()).stream()
                        .map(l -> WmsOutboundEventMessage.StoreCarton.builder()
                                .storeExternalId(l.getStoreExternalId())
                                .storeNumber(l.getStoreNumber())
                                .storeName(l.getStoreName())
                                .city(l.getCity())
                                .stateCode(l.getStateCode())
                                .quantity(l.getQuantity())
                                .cartonLabel(l.getCartonLabel())
                                .build())
                        .collect(Collectors.toList());

        publisher.publishShipmentDispatched(buildShipmentMessage(saved, saved.getPickWave(),
                "SHIPMENT_DISPATCHED", triggeredBy, notes, cartons));
        waveService.recordEvent("SHIPMENT", saved.getId(), "SHIPMENT_DISPATCHED",
                prev, "DISPATCHED",
                saved.getTotalCartons() + " cartons dispatched via " + saved.getCarrierName()
                        + " PRO " + saved.getProNumber(),
                triggeredBy, true);

        log.info("Shipment dispatched: shipmentNumber={} carrier={} pro={}",
                saved.getShipmentNumber(), saved.getCarrierName(), saved.getProNumber());
        return toResponse(saved);
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public ShipmentResponse getShipment(String externalId) {
        return toResponse(findOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<ShipmentResponse> getAllShipments() {
        return shipmentRepo.findAll().stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ShipmentResponse> getShipmentsByStatus(String status) {
        return shipmentRepo.findByStatus(OutboundShipment.Status.valueOf(status))
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ShipmentResponse> getShipmentsByCampaign(String campaignCode) {
        return shipmentRepo.findByCampaignCode(campaignCode)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<OutboundEventResponse> getShipmentEvents(String externalId) {
        OutboundShipment shipment = findOrThrow(externalId);
        return eventRepo.findByEntityTypeAndEntityIdOrderByEventAtDesc("SHIPMENT", shipment.getId())
                .stream().map(this::toEventResponse).collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    private OutboundShipment findOrThrow(String externalId) {
        return shipmentRepo.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException("Shipment not found: " + externalId));
    }

    private void requireStatus(OutboundShipment s, OutboundShipment.Status required, String action) {
        if (s.getStatus() != required) {
            throw new InvalidStateException(
                    "Shipment must be " + required.name() + " to be " + action
                            + ". Current: " + s.getStatus());
        }
    }

    private WmsOutboundEventMessage buildShipmentMessage(OutboundShipment s, PickWave wave,
                                                           String eventType, String triggeredBy,
                                                           String notes,
                                                           List<WmsOutboundEventMessage.StoreCarton> cartons) {
        return WmsOutboundEventMessage.builder()
                .eventType(eventType)
                .waveExternalId(wave != null ? wave.getExternalId() : null)
                .waveNumber(wave != null ? wave.getWaveNumber() : null)
                .shipmentExternalId(s.getExternalId())
                .shipmentNumber(s.getShipmentNumber())
                .shipmentStatus(s.getStatus().name())
                .storeOrderExternalId(s.getStoreOrderExternalId())
                .storeOrderNumber(s.getStoreOrderNumber())
                .campaignExternalId(s.getCampaignExternalId())
                .campaignCode(s.getCampaignCode())
                .regionCode(s.getRegionCode())
                .distributionDc(s.getDistributionDc())
                .sku(s.getSku())
                .toyDescription(s.getToyDescription())
                .totalCartons(s.getTotalCartons())
                .totalUnits(s.getTotalUnits())
                .carrierName(s.getCarrierName())
                .proNumber(s.getProNumber())
                .requiredDeliveryDate(s.getRequiredDeliveryDate())
                .actualShipDate(s.getActualShipDate())
                .storeCartons(cartons)
                .triggeredBy(triggeredBy)
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    public ShipmentResponse toResponse(OutboundShipment s) {
        List<ShipmentStoreLine> lines = storeLineRepo.findByShipmentId(s.getId());
        PickWave wave = s.getPickWave();
        return ShipmentResponse.builder()
                .externalId(s.getExternalId())
                .shipmentNumber(s.getShipmentNumber())
                .waveNumber(wave != null ? wave.getWaveNumber() : null)
                .storeOrderExternalId(s.getStoreOrderExternalId())
                .storeOrderNumber(s.getStoreOrderNumber())
                .campaignExternalId(s.getCampaignExternalId())
                .campaignCode(s.getCampaignCode())
                .regionCode(s.getRegionCode())
                .distributionDc(s.getDistributionDc())
                .sku(s.getSku())
                .toyDescription(s.getToyDescription())
                .totalCartons(s.getTotalCartons())
                .totalUnits(s.getTotalUnits())
                .unitsPerCarton(s.getUnitsPerCarton())
                .carrierName(s.getCarrierName())
                .proNumber(s.getProNumber())
                .destinationRegion(s.getDestinationRegion())
                .requiredDeliveryDate(s.getRequiredDeliveryDate())
                .estimatedShipDate(s.getEstimatedShipDate())
                .actualShipDate(s.getActualShipDate())
                .status(s.getStatus().name())
                .notes(s.getNotes())
                .createdBy(s.getCreatedBy())
                .createdAt(s.getCreatedAt())
                .updatedAt(s.getUpdatedAt())
                .storeLines(lines.stream().map(l -> ShipmentResponse.StoreLineResponse.builder()
                        .storeExternalId(l.getStoreExternalId())
                        .storeNumber(l.getStoreNumber())
                        .storeName(l.getStoreName())
                        .city(l.getCity())
                        .stateCode(l.getStateCode())
                        .quantity(l.getQuantity())
                        .cartonLabel(l.getCartonLabel())
                        .status(l.getStatus().name())
                        .build()).collect(Collectors.toList()))
                .build();
    }

    private OutboundEventResponse toEventResponse(OutboundEvent e) {
        return OutboundEventResponse.builder()
                .id(e.getId()).entityType(e.getEntityType())
                .eventType(e.getEventType()).previousStatus(e.getPreviousStatus())
                .newStatus(e.getNewStatus()).notes(e.getNotes())
                .triggeredBy(e.getTriggeredBy()).rabbitmqPublished(e.isRabbitmqPublished())
                .eventAt(e.getEventAt()).build();
    }
}
