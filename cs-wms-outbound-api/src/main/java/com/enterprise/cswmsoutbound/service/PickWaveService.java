package com.enterprise.cswmsoutbound.service;

import com.enterprise.cswmsoutbound.dto.request.CreatePickWaveRequest;
import com.enterprise.cswmsoutbound.dto.response.OutboundEventResponse;
import com.enterprise.cswmsoutbound.dto.response.PickWaveResponse;
import com.enterprise.cswmsoutbound.entity.*;
import com.enterprise.cswmsoutbound.exception.*;
import com.enterprise.cswmsoutbound.messaging.WmsOutboundEventMessage;
import com.enterprise.cswmsoutbound.messaging.WmsOutboundEventPublisher;
import com.enterprise.cswmsoutbound.repository.*;
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
public class PickWaveService {

    private final PickWaveRepository       waveRepo;
    private final PickWaveLineRepository   lineRepo;
    private final OutboundEventRepository  eventRepo;
    private final WmsOutboundEventPublisher publisher;

    // ── CREATE ────────────────────────────────────────────────────────────────

    @Transactional
    public PickWaveResponse createWave(CreatePickWaveRequest req) {
        if (waveRepo.existsByWaveNumber(req.getWaveNumber())) {
            throw new DuplicateResourceException(
                    "Wave number already exists: " + req.getWaveNumber());
        }

        PickWave wave = PickWave.builder()
                .externalId(UUID.randomUUID().toString())
                .waveNumber(req.getWaveNumber())
                .storeOrderExternalId(req.getStoreOrderExternalId())
                .storeOrderNumber(req.getStoreOrderNumber())
                .campaignExternalId(req.getCampaignExternalId())
                .campaignCode(req.getCampaignCode())
                .regionCode(req.getRegionCode())
                .sku(req.getSku())
                .toyDescription(req.getToyDescription())
                .totalQuantity(req.getTotalQuantity())
                .pickedQuantity(0)
                .pickZone(req.getPickZone())
                .requiredShipDate(req.getRequiredShipDate())
                .status(PickWave.Status.CREATED)
                .notes(req.getNotes())
                .createdBy(req.getCreatedBy())
                .build();

        wave = waveRepo.save(wave);

        // Add bin source lines
        if (req.getBinSources() != null && !req.getBinSources().isEmpty()) {
            for (CreatePickWaveRequest.BinSource src : req.getBinSources()) {
                PickWaveLine line = PickWaveLine.builder()
                        .externalId(UUID.randomUUID().toString())
                        .pickWave(wave)
                        .sku(wave.getSku())
                        .warehouseZone(src.getWarehouseZone())
                        .warehouseAisle(src.getWarehouseAisle())
                        .warehouseBin(src.getWarehouseBin())
                        .quantityToPick(src.getQuantityToPick())
                        .quantityPicked(0)
                        .status(PickWaveLine.Status.PENDING)
                        .build();
                lineRepo.save(line);
            }
        }

        recordEvent("PICK_WAVE", wave.getId(), "WAVE_CREATED", null, "CREATED",
                "Pick wave created for order " + wave.getStoreOrderNumber(), req.getCreatedBy(), false);

        publisher.publishWaveCreated(buildWaveMessage(wave, "WAVE_CREATED", req.getCreatedBy(), req.getNotes()));

        log.info("Pick wave created: waveNumber={} order={} qty={}",
                wave.getWaveNumber(), wave.getStoreOrderNumber(), wave.getTotalQuantity());
        return toWaveResponse(wave);
    }

    // ── ASSIGN ────────────────────────────────────────────────────────────────

    @Transactional
    public PickWaveResponse assignWave(String externalId, String assignedTo, String notes) {
        PickWave wave = findWaveOrThrow(externalId);
        requireWaveStatus(wave, PickWave.Status.CREATED, "assigned");

        String prev = wave.getStatus().name();
        wave.setAssignedTo(assignedTo);
        wave.setStatus(PickWave.Status.ASSIGNED);
        final PickWave saved = waveRepo.save(wave);

        recordEvent("PICK_WAVE", saved.getId(), "WAVE_ASSIGNED", prev, "ASSIGNED",
                "Assigned to " + assignedTo, assignedTo, false);

        log.info("Wave assigned: waveNumber={} to={}", saved.getWaveNumber(), assignedTo);
        return toWaveResponse(saved);
    }

    // ── START PICKING ─────────────────────────────────────────────────────────

    @Transactional
    public PickWaveResponse startPicking(String externalId, String triggeredBy, String notes) {
        PickWave wave = findWaveOrThrow(externalId);
        if (wave.getStatus() != PickWave.Status.ASSIGNED && wave.getStatus() != PickWave.Status.CREATED) {
            throw new InvalidStateException(
                    "Wave must be CREATED or ASSIGNED to start picking. Current: " + wave.getStatus());
        }

        String prev = wave.getStatus().name();
        wave.setStatus(PickWave.Status.PICKING);
        wave.setStartedAt(LocalDateTime.now());
        final PickWave saved = waveRepo.save(wave);

        recordEvent("PICK_WAVE", saved.getId(), "WAVE_PICKING", prev, "PICKING",
                notes, triggeredBy, false);

        log.info("Wave picking started: waveNumber={}", saved.getWaveNumber());
        return toWaveResponse(saved);
    }

    // ── COMPLETE WAVE ─────────────────────────────────────────────────────────

    @Transactional
    public PickWaveResponse completeWave(String externalId, int pickedQuantity,
                                          String triggeredBy, String notes) {
        PickWave wave = findWaveOrThrow(externalId);
        requireWaveStatus(wave, PickWave.Status.PICKING, "completed");

        String prev = wave.getStatus().name();
        wave.setPickedQuantity(pickedQuantity);
        wave.setStatus(PickWave.Status.COMPLETED);
        wave.setCompletedAt(LocalDateTime.now());
        final PickWave saved = waveRepo.save(wave);

        // Mark all lines PICKED
        lineRepo.findByPickWaveId(saved.getId()).forEach(l -> {
            l.setQuantityPicked(l.getQuantityToPick());
            l.setStatus(PickWaveLine.Status.PICKED);
            lineRepo.save(l);
        });

        publisher.publishWaveCompleted(buildWaveMessage(saved, "WAVE_COMPLETED", triggeredBy, notes));
        recordEvent("PICK_WAVE", saved.getId(), "WAVE_COMPLETED", prev, "COMPLETED",
                pickedQuantity + " units picked. " + notes, triggeredBy, true);

        log.info("Wave completed: waveNumber={} picked={}", saved.getWaveNumber(), pickedQuantity);
        return toWaveResponse(saved);
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PickWaveResponse getWave(String externalId) {
        return toWaveResponse(findWaveOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<PickWaveResponse> getAllWaves() {
        return waveRepo.findAll().stream().map(this::toWaveResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PickWaveResponse> getWavesByStatus(String status) {
        return waveRepo.findByStatus(PickWave.Status.valueOf(status))
                .stream().map(this::toWaveResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<OutboundEventResponse> getWaveEvents(String externalId) {
        PickWave wave = findWaveOrThrow(externalId);
        return eventRepo.findByEntityTypeAndEntityIdOrderByEventAtDesc("PICK_WAVE", wave.getId())
                .stream().map(this::toEventResponse).collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    public PickWave findWaveOrThrow(String externalId) {
        return waveRepo.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException("Pick wave not found: " + externalId));
    }

    private void requireWaveStatus(PickWave wave, PickWave.Status required, String action) {
        if (wave.getStatus() != required) {
            throw new InvalidStateException(
                    "Wave must be " + required.name() + " to be " + action
                            + ". Current: " + wave.getStatus());
        }
    }

    void recordEvent(String entityType, Long entityId, String type,
                     String prev, String next, String notes, String by, boolean published) {
        eventRepo.save(OutboundEvent.builder()
                .entityType(entityType).entityId(entityId)
                .eventType(type).previousStatus(prev).newStatus(next)
                .notes(notes).triggeredBy(by)
                .eventAt(LocalDateTime.now()).rabbitmqPublished(published).build());
    }

    WmsOutboundEventMessage buildWaveMessage(PickWave wave, String eventType,
                                              String triggeredBy, String notes) {
        return WmsOutboundEventMessage.builder()
                .eventType(eventType)
                .waveExternalId(wave.getExternalId())
                .waveNumber(wave.getWaveNumber())
                .waveStatus(wave.getStatus().name())
                .storeOrderExternalId(wave.getStoreOrderExternalId())
                .storeOrderNumber(wave.getStoreOrderNumber())
                .campaignExternalId(wave.getCampaignExternalId())
                .campaignCode(wave.getCampaignCode())
                .regionCode(wave.getRegionCode())
                .sku(wave.getSku())
                .toyDescription(wave.getToyDescription())
                .totalUnits(wave.getTotalQuantity())
                .requiredDeliveryDate(wave.getRequiredShipDate())
                .triggeredBy(triggeredBy)
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    public PickWaveResponse toWaveResponse(PickWave w) {
        List<PickWaveLine> lines = lineRepo.findByPickWaveId(w.getId());
        return PickWaveResponse.builder()
                .externalId(w.getExternalId())
                .waveNumber(w.getWaveNumber())
                .storeOrderExternalId(w.getStoreOrderExternalId())
                .storeOrderNumber(w.getStoreOrderNumber())
                .campaignExternalId(w.getCampaignExternalId())
                .campaignCode(w.getCampaignCode())
                .regionCode(w.getRegionCode())
                .sku(w.getSku())
                .toyDescription(w.getToyDescription())
                .totalQuantity(w.getTotalQuantity())
                .pickedQuantity(w.getPickedQuantity())
                .pickZone(w.getPickZone())
                .assignedTo(w.getAssignedTo())
                .requiredShipDate(w.getRequiredShipDate())
                .startedAt(w.getStartedAt())
                .completedAt(w.getCompletedAt())
                .status(w.getStatus().name())
                .notes(w.getNotes())
                .createdBy(w.getCreatedBy())
                .createdAt(w.getCreatedAt())
                .lines(lines.stream().map(l -> PickWaveResponse.PickWaveLineResponse.builder()
                        .externalId(l.getExternalId())
                        .warehouseZone(l.getWarehouseZone())
                        .warehouseAisle(l.getWarehouseAisle())
                        .warehouseBin(l.getWarehouseBin())
                        .quantityToPick(l.getQuantityToPick())
                        .quantityPicked(l.getQuantityPicked())
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
