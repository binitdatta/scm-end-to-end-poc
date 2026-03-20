package com.enterprise.cstms.service;

import com.enterprise.cstms.dto.request.*;
import com.enterprise.cstms.dto.response.*;
import com.enterprise.cstms.entity.*;
import com.enterprise.cstms.exception.*;
import com.enterprise.cstms.messaging.TmsEventMessage;
import com.enterprise.cstms.messaging.TmsEventPublisher;
import com.enterprise.cstms.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeliveryLoadService {

    private final DeliveryLoadRepository   loadRepo;
    private final StoreDeliveryRepository  storeDeliveryRepo;
    private final TransitEventRepository   transitRepo;
    private final TmsEventRepository       tmsEventRepo;
    private final TmsEventPublisher        publisher;

    // ── CREATE LOAD ───────────────────────────────────────────────────────────

    @Transactional
    public DeliveryLoadResponse createLoad(CreateDeliveryLoadRequest req) {
        if (loadRepo.existsByLoadNumber(req.getLoadNumber())) {
            throw new DuplicateResourceException(
                    "Load number already exists: " + req.getLoadNumber());
        }
        if (loadRepo.existsByShipmentExternalId(req.getShipmentExternalId())) {
            throw new DuplicateResourceException(
                    "Load already exists for shipment: " + req.getShipmentExternalId());
        }

        DeliveryLoad load = DeliveryLoad.builder()
                .externalId(UUID.randomUUID().toString())
                .loadNumber(req.getLoadNumber())
                .shipmentExternalId(req.getShipmentExternalId())
                .shipmentNumber(req.getShipmentNumber())
                .storeOrderExternalId(req.getStoreOrderExternalId())
                .storeOrderNumber(req.getStoreOrderNumber())
                .campaignExternalId(req.getCampaignExternalId())
                .campaignCode(req.getCampaignCode())
                .regionCode(req.getRegionCode())
                .distributionDc(req.getDistributionDc())
                .sku(req.getSku())
                .toyDescription(req.getToyDescription())
                .totalCartons(req.getTotalCartons())
                .totalUnits(req.getTotalUnits())
                .carrierName(req.getCarrierName())
                .proNumber(req.getProNumber())
                .requiredDeliveryDate(req.getRequiredDeliveryDate())
                .status(DeliveryLoad.Status.CREATED)
                .notes(req.getNotes())
                .createdBy(req.getCreatedBy())
                .build();

        load = loadRepo.save(load);

        // Create per-store delivery records
        for (CreateDeliveryLoadRequest.StoreCartonInput sc : req.getStoreCartons()) {
            StoreDelivery sd = StoreDelivery.builder()
                    .externalId(UUID.randomUUID().toString())
                    .deliveryLoad(load)
                    .storeExternalId(sc.getStoreExternalId())
                    .storeNumber(sc.getStoreNumber())
                    .storeName(sc.getStoreName())
                    .city(sc.getCity())
                    .stateCode(sc.getStateCode())
                    .sku(sc.getSku())
                    .quantity(sc.getQuantity())
                    .cartonLabel(sc.getCartonLabel())
                    .status(StoreDelivery.Status.PENDING)
                    .build();
            storeDeliveryRepo.save(sd);
        }

        recordEvent(load, "LOAD_CREATED", null, "CREATED",
                "Load created from WMS shipment " + load.getShipmentNumber(),
                req.getCreatedBy(), true);
        publisher.publishLoadCreated(buildMessage(load, "LOAD_CREATED",
                req.getCreatedBy(), req.getNotes(), null));

        log.info("Delivery load created: loadNumber={} shipment={} cartons={}",
                load.getLoadNumber(), load.getShipmentNumber(), load.getTotalCartons());
        return toResponse(load);
    }

    // ── ASSIGN DRIVER ─────────────────────────────────────────────────────────

    @Transactional
    public DeliveryLoadResponse assignDriver(String externalId, AssignDriverRequest req) {
        DeliveryLoad load = findOrThrow(externalId);
        requireStatus(load, DeliveryLoad.Status.CREATED, "assigned");

        String prev = load.getStatus().name();
        load.setDriverName(req.getDriverName());
        load.setTruckNumber(req.getTruckNumber());
        if (req.getPickupDate() != null) load.setPickupDate(req.getPickupDate());
        if (req.getEstimatedDeliveryDate() != null)
            load.setEstimatedDeliveryDate(req.getEstimatedDeliveryDate());
        load.setStatus(DeliveryLoad.Status.ASSIGNED);
        final DeliveryLoad saved = loadRepo.save(load);

        publisher.publishLoadAssigned(buildMessage(saved, "LOAD_ASSIGNED",
                "tms.coordinator", req.getNotes(), null));
        recordEvent(saved, "LOAD_ASSIGNED", prev, "ASSIGNED",
                "Driver: " + req.getDriverName() + " Truck: " + req.getTruckNumber(),
                "tms.coordinator", true);

        log.info("Load assigned: loadNumber={} driver={} truck={}",
                saved.getLoadNumber(), req.getDriverName(), req.getTruckNumber());
        return toResponse(saved);
    }

    // ── MARK IN TRANSIT ───────────────────────────────────────────────────────

    @Transactional
    public DeliveryLoadResponse markInTransit(String externalId, String triggeredBy, String notes) {
        DeliveryLoad load = findOrThrow(externalId);
        requireStatus(load, DeliveryLoad.Status.ASSIGNED, "in transit");

        String prev = load.getStatus().name();
        load.setStatus(DeliveryLoad.Status.IN_TRANSIT);
        final DeliveryLoad saved = loadRepo.save(load);

        publisher.publishLoadInTransit(buildMessage(saved, "LOAD_IN_TRANSIT",
                triggeredBy, notes, null));
        recordEvent(saved, "LOAD_IN_TRANSIT", prev, "IN_TRANSIT",
                "PRO: " + saved.getProNumber() + ". " + notes, triggeredBy, true);

        // Mark all store deliveries OUT_FOR_DELIVERY
        storeDeliveryRepo.findByDeliveryLoadId(saved.getId()).forEach(sd -> {
            sd.setStatus(StoreDelivery.Status.OUT_FOR_DELIVERY);
            storeDeliveryRepo.save(sd);
        });

        publisher.publishOutForDelivery(buildMessage(saved, "DELIVERY_OUT_FOR_DELIVERY",
                triggeredBy, "All stores out for delivery", null));

        log.info("Load in transit: loadNumber={} PRO={}", saved.getLoadNumber(), saved.getProNumber());
        return toResponse(saved);
    }

    // ── RECORD TRANSIT EVENT ──────────────────────────────────────────────────

    @Transactional
    public TransitEventResponse recordTransitEvent(String externalId, RecordTransitEventRequest req) {
        DeliveryLoad load = findOrThrow(externalId);

        TransitEvent event = TransitEvent.builder()
                .deliveryLoad(load)
                .eventCode(req.getEventCode())
                .eventDescription(req.getEventDescription())
                .location(req.getLocation())
                .eventAt(req.getEventAt() != null ? req.getEventAt() : LocalDateTime.now())
                .source(req.getSource() != null ? req.getSource() : "MANUAL")
                .build();

        event = transitRepo.save(event);
        log.info("Transit event recorded: loadNumber={} code={} loc={}",
                load.getLoadNumber(), req.getEventCode(), req.getLocation());
        return toTransitResponse(event);
    }

    // ── CONFIRM POD FOR ONE STORE ─────────────────────────────────────────────

    @Transactional
    public StoreDeliveryResponse confirmPod(String loadExternalId, String storeDeliveryExternalId,
                                             ConfirmPodRequest req) {
        DeliveryLoad load = findOrThrow(loadExternalId);

        if (load.getStatus() != DeliveryLoad.Status.IN_TRANSIT
                && load.getStatus() != DeliveryLoad.Status.ASSIGNED) {
            throw new InvalidStateException(
                    "Load must be IN_TRANSIT or ASSIGNED to confirm POD. Current: " + load.getStatus());
        }

        StoreDelivery sd = storeDeliveryRepo.findByExternalId(storeDeliveryExternalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Store delivery not found: " + storeDeliveryExternalId));

        if (!sd.getDeliveryLoad().getId().equals(load.getId())) {
            throw new InvalidStateException("Store delivery does not belong to this load");
        }

        sd.setDeliveredQuantity(req.getDeliveredQuantity());
        sd.setPodSignatory(req.getPodSignatory());
        sd.setPodNotes(req.getPodNotes());
        sd.setDeliveredAt(req.getDeliveredAt() != null ? req.getDeliveredAt() : LocalDateTime.now());
        sd.setPodConfirmedAt(LocalDateTime.now());
        sd.setStatus(StoreDelivery.Status.POD_CONFIRMED);
        storeDeliveryRepo.save(sd);

        log.info("POD confirmed: store={} load={} qty={}",
                sd.getStoreNumber(), load.getLoadNumber(), req.getDeliveredQuantity());

        // Check if ALL store deliveries are now POD_CONFIRMED → complete the load
        checkAndCompleteLoad(load);

        return toStoreDeliveryResponse(sd);
    }

    // ── AUTO-COMPLETE LOAD WHEN ALL STORES POD CONFIRMED ─────────────────────

    private void checkAndCompleteLoad(DeliveryLoad load) {
        List<StoreDelivery> all = storeDeliveryRepo.findByDeliveryLoadId(load.getId());
        boolean allConfirmed = all.stream()
                .allMatch(sd -> sd.getStatus() == StoreDelivery.Status.POD_CONFIRMED);

        if (!allConfirmed) return;

        String prev = load.getStatus().name();
        load.setStatus(DeliveryLoad.Status.COMPLETED);
        final DeliveryLoad saved = loadRepo.save(load);

        // Build full POD summary for the KEY final event
        List<TmsEventMessage.StorePod> pods = all.stream()
                .map(sd -> TmsEventMessage.StorePod.builder()
                        .storeExternalId(sd.getStoreExternalId())
                        .storeNumber(sd.getStoreNumber())
                        .storeName(sd.getStoreName())
                        .city(sd.getCity())
                        .stateCode(sd.getStateCode())
                        .quantity(sd.getQuantity())
                        .deliveredQuantity(sd.getDeliveredQuantity())
                        .podSignatory(sd.getPodSignatory())
                        .deliveredAt(sd.getDeliveredAt())
                        .podConfirmedAt(sd.getPodConfirmedAt())
                        .build())
                .collect(Collectors.toList());

        int totalDelivered = all.stream()
                .mapToInt(sd -> sd.getDeliveredQuantity() != null ? sd.getDeliveredQuantity() : 0).sum();

        TmsEventMessage podMsg = buildMessage(saved, "DELIVERY_POD_CONFIRMED",
                "tms.coordinator", "All " + all.size() + " stores POD confirmed.", pods);
        podMsg.setTotalStoresDelivered(all.size());
        podMsg.setTotalUnitsDelivered(totalDelivered);

        // KEY final event — consumed by Flask Control Tower
        publisher.publishPodConfirmed(podMsg);
        publisher.publishLoadCompleted(buildMessage(saved, "LOAD_COMPLETED",
                "tms.coordinator", "All stores delivered and POD confirmed.", null));

        recordEvent(saved, "LOAD_COMPLETED", prev, "COMPLETED",
                "All " + all.size() + " stores POD confirmed. Total delivered: " + totalDelivered,
                "tms.coordinator", true);

        log.info("Load COMPLETED: loadNumber={} stores={} totalDelivered={}",
                saved.getLoadNumber(), all.size(), totalDelivered);
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public DeliveryLoadResponse getLoad(String externalId) {
        return toResponse(findOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<DeliveryLoadResponse> getAllLoads() {
        return loadRepo.findAll().stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<DeliveryLoadResponse> getLoadsByStatus(String status) {
        return loadRepo.findByStatus(DeliveryLoad.Status.valueOf(status))
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<DeliveryLoadResponse> getLoadsByCampaign(String campaignCode) {
        return loadRepo.findByCampaignCode(campaignCode)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TransitEventResponse> getTransitEvents(String externalId) {
        DeliveryLoad load = findOrThrow(externalId);
        return transitRepo.findByDeliveryLoadIdOrderByEventAtDesc(load.getId())
                .stream().map(this::toTransitResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TmsEventResponse> getTmsEvents(String externalId) {
        DeliveryLoad load = findOrThrow(externalId);
        return tmsEventRepo.findByDeliveryLoadIdOrderByEventAtDesc(load.getId())
                .stream().map(this::toTmsEventResponse).collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    public DeliveryLoad findOrThrow(String externalId) {
        return loadRepo.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Delivery load not found: " + externalId));
    }

    private void requireStatus(DeliveryLoad load, DeliveryLoad.Status required, String action) {
        if (load.getStatus() != required) {
            throw new InvalidStateException(
                    "Load must be " + required.name() + " to be " + action
                            + ". Current: " + load.getStatus());
        }
    }

    private void recordEvent(DeliveryLoad load, String type, String prev, String next,
                              String notes, String by, boolean published) {
        tmsEventRepo.save(TmsEvent.builder()
                .deliveryLoad(load).eventType(type).previousStatus(prev).newStatus(next)
                .notes(notes).triggeredBy(by)
                .eventAt(LocalDateTime.now()).rabbitmqPublished(published).build());
    }

    private TmsEventMessage buildMessage(DeliveryLoad load, String eventType,
                                          String triggeredBy, String notes,
                                          List<TmsEventMessage.StorePod> pods) {
        return TmsEventMessage.builder()
                .eventType(eventType)
                .loadExternalId(load.getExternalId())
                .loadNumber(load.getLoadNumber())
                .loadStatus(load.getStatus().name())
                .shipmentExternalId(load.getShipmentExternalId())
                .shipmentNumber(load.getShipmentNumber())
                .storeOrderExternalId(load.getStoreOrderExternalId())
                .storeOrderNumber(load.getStoreOrderNumber())
                .campaignExternalId(load.getCampaignExternalId())
                .campaignCode(load.getCampaignCode())
                .regionCode(load.getRegionCode())
                .distributionDc(load.getDistributionDc())
                .sku(load.getSku())
                .toyDescription(load.getToyDescription())
                .totalCartons(load.getTotalCartons())
                .totalUnits(load.getTotalUnits())
                .carrierName(load.getCarrierName())
                .proNumber(load.getProNumber())
                .driverName(load.getDriverName())
                .truckNumber(load.getTruckNumber())
                .requiredDeliveryDate(load.getRequiredDeliveryDate())
                .pickupDate(load.getPickupDate())
                .storePods(pods)
                .triggeredBy(triggeredBy)
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    public DeliveryLoadResponse toResponse(DeliveryLoad l) {
        List<StoreDelivery> sds = storeDeliveryRepo.findByDeliveryLoadId(l.getId());
        return DeliveryLoadResponse.builder()
                .externalId(l.getExternalId())
                .loadNumber(l.getLoadNumber())
                .shipmentExternalId(l.getShipmentExternalId())
                .shipmentNumber(l.getShipmentNumber())
                .storeOrderExternalId(l.getStoreOrderExternalId())
                .storeOrderNumber(l.getStoreOrderNumber())
                .campaignExternalId(l.getCampaignExternalId())
                .campaignCode(l.getCampaignCode())
                .regionCode(l.getRegionCode())
                .distributionDc(l.getDistributionDc())
                .sku(l.getSku())
                .toyDescription(l.getToyDescription())
                .totalCartons(l.getTotalCartons())
                .totalUnits(l.getTotalUnits())
                .carrierName(l.getCarrierName())
                .proNumber(l.getProNumber())
                .driverName(l.getDriverName())
                .truckNumber(l.getTruckNumber())
                .requiredDeliveryDate(l.getRequiredDeliveryDate())
                .pickupDate(l.getPickupDate())
                .estimatedDeliveryDate(l.getEstimatedDeliveryDate())
                .status(l.getStatus().name())
                .notes(l.getNotes())
                .createdBy(l.getCreatedBy())
                .createdAt(l.getCreatedAt())
                .updatedAt(l.getUpdatedAt())
                .storeDeliveries(sds.stream().map(this::toStoreDeliveryResponse).collect(Collectors.toList()))
                .build();
    }

    private StoreDeliveryResponse toStoreDeliveryResponse(StoreDelivery sd) {
        return StoreDeliveryResponse.builder()
                .externalId(sd.getExternalId())
                .storeExternalId(sd.getStoreExternalId())
                .storeNumber(sd.getStoreNumber())
                .storeName(sd.getStoreName())
                .city(sd.getCity())
                .stateCode(sd.getStateCode())
                .sku(sd.getSku())
                .quantity(sd.getQuantity())
                .cartonLabel(sd.getCartonLabel())
                .deliveredQuantity(sd.getDeliveredQuantity())
                .podSignatory(sd.getPodSignatory())
                .podNotes(sd.getPodNotes())
                .status(sd.getStatus().name())
                .deliveredAt(sd.getDeliveredAt())
                .podConfirmedAt(sd.getPodConfirmedAt())
                .build();
    }

    private TransitEventResponse toTransitResponse(TransitEvent te) {
        return TransitEventResponse.builder()
                .id(te.getId()).eventCode(te.getEventCode())
                .eventDescription(te.getEventDescription()).location(te.getLocation())
                .source(te.getSource()).eventAt(te.getEventAt()).recordedAt(te.getRecordedAt())
                .build();
    }

    private TmsEventResponse toTmsEventResponse(TmsEvent e) {
        return TmsEventResponse.builder()
                .id(e.getId()).eventType(e.getEventType())
                .previousStatus(e.getPreviousStatus()).newStatus(e.getNewStatus())
                .notes(e.getNotes()).triggeredBy(e.getTriggeredBy())
                .rabbitmqPublished(e.isRabbitmqPublished()).eventAt(e.getEventAt())
                .build();
    }
}
