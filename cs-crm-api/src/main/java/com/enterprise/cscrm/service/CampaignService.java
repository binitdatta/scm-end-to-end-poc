package com.enterprise.cscrm.service;

import com.enterprise.cscrm.dto.request.CreateCampaignRequest;
import com.enterprise.cscrm.dto.request.LaunchCampaignRequest;
import com.enterprise.cscrm.dto.response.CampaignResponse;
import com.enterprise.cscrm.entity.Campaign;
import com.enterprise.cscrm.entity.CampaignEvent;
import com.enterprise.cscrm.exception.DuplicateResourceException;
import com.enterprise.cscrm.exception.InvalidStateException;
import com.enterprise.cscrm.exception.ResourceNotFoundException;
import com.enterprise.cscrm.messaging.CampaignEventMessage;
import com.enterprise.cscrm.messaging.CampaignEventPublisher;
import com.enterprise.cscrm.repository.CampaignEventRepository;
import com.enterprise.cscrm.repository.CampaignRepository;
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
public class CampaignService {

    private final CampaignRepository      campaignRepository;
    private final CampaignEventRepository campaignEventRepository;
    private final CampaignEventPublisher  publisher;

    // ── CREATE ────────────────────────────────────────────────────────────────

    @Transactional
    public CampaignResponse createCampaign(CreateCampaignRequest req) {
        if (campaignRepository.existsByCampaignCode(req.getCampaignCode())) {
            throw new DuplicateResourceException(
                    "Campaign code already exists: " + req.getCampaignCode());
        }

        Campaign campaign = Campaign.builder()
                .externalId(UUID.randomUUID().toString())
                .campaignName(req.getCampaignName())
                .campaignCode(req.getCampaignCode())
                .description(req.getDescription())
                .campaignType(Campaign.CampaignType.valueOf(req.getCampaignType()))
                .status(Campaign.Status.DRAFT)
                .budgetUsd(req.getBudgetUsd())
                .startDate(req.getStartDate())
                .endDate(req.getEndDate())
                .targetRegion(req.getTargetRegion())
                .createdBy(req.getCreatedBy())
                .build();

        campaign = campaignRepository.save(campaign);
        recordEvent(campaign, "CREATED", null, "DRAFT", "Campaign created", req.getCreatedBy(), false);

        log.info("Campaign created: code={} id={}", campaign.getCampaignCode(), campaign.getExternalId());
        return toResponse(campaign);
    }

    // ── LAUNCH ────────────────────────────────────────────────────────────────

    @Transactional
    public CampaignResponse launchCampaign(String externalId, LaunchCampaignRequest req) {
        Campaign campaign = findByExternalIdOrThrow(externalId);

        if (campaign.getStatus() != Campaign.Status.DRAFT) {
            throw new InvalidStateException(
                    "Campaign can only be launched from DRAFT status. Current: " + campaign.getStatus());
        }

        String previousStatus = campaign.getStatus().name();
        campaign.setStatus(Campaign.Status.ACTIVE);
        campaign = campaignRepository.save(campaign);

        // Publish RabbitMQ event AFTER successful DB commit
        CampaignEventMessage message = buildEventMessage(campaign, previousStatus, "ACTIVE",
                "LAUNCHED", req.getTriggeredBy(), req.getNotes());
        publisher.publishCampaignLaunched(message);

        // Record audit event with published=true
        recordEvent(campaign, "LAUNCHED", previousStatus, "ACTIVE",
                req.getNotes(), req.getTriggeredBy(), true);

        log.info("Campaign launched: code={}", campaign.getCampaignCode());
        return toResponse(campaign);
    }

    // ── PAUSE ─────────────────────────────────────────────────────────────────

    @Transactional
    public CampaignResponse pauseCampaign(String externalId, String triggeredBy, String notes) {
        Campaign campaign = findByExternalIdOrThrow(externalId);

        if (campaign.getStatus() != Campaign.Status.ACTIVE) {
            throw new InvalidStateException(
                    "Campaign can only be paused from ACTIVE status. Current: " + campaign.getStatus());
        }

        String previousStatus = campaign.getStatus().name();
        campaign.setStatus(Campaign.Status.PAUSED);
        campaign = campaignRepository.save(campaign);

        CampaignEventMessage message = buildEventMessage(campaign, previousStatus, "PAUSED",
                "PAUSED", triggeredBy, notes);
        publisher.publishCampaignPaused(message);

        recordEvent(campaign, "PAUSED", previousStatus, "PAUSED", notes, triggeredBy, true);

        log.info("Campaign paused: code={}", campaign.getCampaignCode());
        return toResponse(campaign);
    }

    // ── COMPLETE ──────────────────────────────────────────────────────────────

    @Transactional
    public CampaignResponse completeCampaign(String externalId, String triggeredBy, String notes) {
        Campaign campaign = findByExternalIdOrThrow(externalId);

        if (campaign.getStatus() != Campaign.Status.ACTIVE
                && campaign.getStatus() != Campaign.Status.PAUSED) {
            throw new InvalidStateException(
                    "Campaign can only be completed from ACTIVE or PAUSED. Current: " + campaign.getStatus());
        }

        String previousStatus = campaign.getStatus().name();
        campaign.setStatus(Campaign.Status.COMPLETED);
        campaign = campaignRepository.save(campaign);

        CampaignEventMessage message = buildEventMessage(campaign, previousStatus, "COMPLETED",
                "COMPLETED", triggeredBy, notes);
        publisher.publishCampaignCompleted(message);

        recordEvent(campaign, "COMPLETED", previousStatus, "COMPLETED", notes, triggeredBy, true);

        log.info("Campaign completed: code={}", campaign.getCampaignCode());
        return toResponse(campaign);
    }

    // ── GET ───────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public CampaignResponse getCampaign(String externalId) {
        return toResponse(findByExternalIdOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<CampaignResponse> getAllCampaigns() {
        return campaignRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    private Campaign findByExternalIdOrThrow(String externalId) {
        return campaignRepository.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Campaign not found: " + externalId));
    }

    private void recordEvent(Campaign campaign, String eventType,
                             String prevStatus, String newStatus,
                             String notes, String triggeredBy,
                             boolean published) {
        CampaignEvent event = CampaignEvent.builder()
                .campaign(campaign)
                .eventType(eventType)
                .previousStatus(prevStatus)
                .newStatus(newStatus)
                .notes(notes)
                .triggeredBy(triggeredBy)
                .eventAt(LocalDateTime.now())
                .rabbitmqPublished(published)
                .build();
        campaignEventRepository.save(event);
    }

    private CampaignEventMessage buildEventMessage(Campaign campaign,
                                                    String prevStatus, String newStatus,
                                                    String eventType, String triggeredBy,
                                                    String notes) {
        return CampaignEventMessage.builder()
                .campaignExternalId(campaign.getExternalId())
                .campaignCode(campaign.getCampaignCode())
                .campaignName(campaign.getCampaignName())
                .previousStatus(prevStatus)
                .newStatus(newStatus)
                .eventType(eventType)
                .triggeredBy(triggeredBy)
                .targetRegion(campaign.getTargetRegion())
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    private CampaignResponse toResponse(Campaign c) {
        return CampaignResponse.builder()
                .externalId(c.getExternalId())
                .campaignName(c.getCampaignName())
                .campaignCode(c.getCampaignCode())
                .description(c.getDescription())
                .campaignType(c.getCampaignType().name())
                .status(c.getStatus().name())
                .budgetUsd(c.getBudgetUsd())
                .startDate(c.getStartDate())
                .endDate(c.getEndDate())
                .targetRegion(c.getTargetRegion())
                .createdBy(c.getCreatedBy())
                .createdAt(c.getCreatedAt())
                .updatedAt(c.getUpdatedAt())
                .build();
    }
}
