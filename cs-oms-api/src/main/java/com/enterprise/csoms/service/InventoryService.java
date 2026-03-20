package com.enterprise.csoms.service;

import com.enterprise.csoms.dto.request.UpdateInventoryRequest;
import com.enterprise.csoms.dto.response.InventoryAvailabilityResponse;
import com.enterprise.csoms.entity.InventoryAvailability;
import com.enterprise.csoms.exception.ResourceNotFoundException;
import com.enterprise.csoms.messaging.OmsEventMessage;
import com.enterprise.csoms.messaging.OmsEventPublisher;
import com.enterprise.csoms.repository.InventoryAvailabilityRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InventoryService {

    private final InventoryAvailabilityRepository inventoryRepo;
    private final OmsEventPublisher               publisher;

    /**
     * Called when erp.wms.inbound.putaway.completed is consumed.
     * Creates or updates the OMS inventory view for the given SKU + campaign.
     */
    @Transactional
    public InventoryAvailabilityResponse updateInventory(UpdateInventoryRequest req) {
        InventoryAvailability inv = inventoryRepo
                .findBySkuAndCampaignCode(req.getSku(), req.getCampaignCode())
                .orElse(InventoryAvailability.builder()
                        .sku(req.getSku())
                        .campaignCode(req.getCampaignCode())
                        .quantityReserved(0)
                        .build());

        inv.setQuantityAvailable(req.getQuantityAvailable());
        inv.setQuantityRemaining(req.getQuantityAvailable() - inv.getQuantityReserved());
        inv.setSourceAsnNumber(req.getSourceAsnNumber());
        inv = inventoryRepo.save(inv);

        // Notify Control Tower
        OmsEventMessage message = OmsEventMessage.builder()
                .eventType("INVENTORY_UPDATED")
                .sku(req.getSku())
                .campaignCode(req.getCampaignCode())
                .quantityAllocated(req.getQuantityAvailable())
                .notes("Inventory updated from ASN: " + req.getSourceAsnNumber())
                .triggeredBy("wms.inbound.putaway.completed")
                .eventTimestamp(LocalDateTime.now())
                .build();
        publisher.publishInventoryUpdated(message);

        log.info("Inventory updated: sku={} campaign={} available={} remaining={}",
                inv.getSku(), inv.getCampaignCode(),
                inv.getQuantityAvailable(), inv.getQuantityRemaining());
        return toResponse(inv);
    }

    @Transactional(readOnly = true)
    public InventoryAvailabilityResponse getInventory(String sku, String campaignCode) {
        InventoryAvailability inv = inventoryRepo
                .findBySkuAndCampaignCode(sku, campaignCode)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No inventory record for SKU=" + sku + " campaign=" + campaignCode));
        return toResponse(inv);
    }

    @Transactional(readOnly = true)
    public List<InventoryAvailabilityResponse> getInventoryByCampaign(String campaignCode) {
        return inventoryRepo.findByCampaignCode(campaignCode)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    private InventoryAvailabilityResponse toResponse(InventoryAvailability i) {
        return InventoryAvailabilityResponse.builder()
                .sku(i.getSku())
                .campaignCode(i.getCampaignCode())
                .quantityAvailable(i.getQuantityAvailable())
                .quantityReserved(i.getQuantityReserved())
                .quantityRemaining(i.getQuantityRemaining())
                .sourceAsnNumber(i.getSourceAsnNumber())
                .lastUpdatedAt(i.getLastUpdatedAt())
                .build();
    }
}
