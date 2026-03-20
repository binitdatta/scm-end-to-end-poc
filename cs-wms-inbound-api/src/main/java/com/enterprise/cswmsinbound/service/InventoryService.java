package com.enterprise.cswmsinbound.service;

import com.enterprise.cswmsinbound.dto.response.InventoryResponse;
import com.enterprise.cswmsinbound.repository.InventoryLocationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InventoryService {

    private final InventoryLocationRepository inventoryRepo;

    @Transactional(readOnly = true)
    public List<InventoryResponse> getInventoryBySku(String sku) {
        return inventoryRepo.findBySku(sku).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<InventoryResponse> getInventoryByCampaign(String campaignCode) {
        return inventoryRepo.findByCampaignCode(campaignCode).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Integer getTotalAvailableBySku(String sku) {
        Integer total = inventoryRepo.sumAvailableQuantityBySku(sku);
        return total != null ? total : 0;
    }

    @Transactional(readOnly = true)
    public Integer getTotalOnHandByCampaign(String campaignCode) {
        Integer total = inventoryRepo.sumOnHandByCampaignCode(campaignCode);
        return total != null ? total : 0;
    }

    private InventoryResponse toResponse(
            com.enterprise.cswmsinbound.entity.InventoryLocation loc) {
        return InventoryResponse.builder()
                .sku(loc.getSku())
                .campaignCode(loc.getCampaignCode())
                .warehouseZone(loc.getWarehouseZone())
                .warehouseAisle(loc.getWarehouseAisle())
                .warehouseBin(loc.getWarehouseBin())
                .quantityOnHand(loc.getQuantityOnHand())
                .quantityReserved(loc.getQuantityReserved())
                .quantityAvailable(loc.getQuantityAvailable())
                .lastReceiptDate(loc.getLastReceiptDate())
                .lastUpdatedAt(loc.getLastUpdatedAt())
                .build();
    }
}
