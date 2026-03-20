package com.enterprise.cswmsinbound.repository;

import com.enterprise.cswmsinbound.entity.InventoryLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface InventoryLocationRepository extends JpaRepository<InventoryLocation, Long> {
    List<InventoryLocation> findBySku(String sku);
    List<InventoryLocation> findByCampaignCode(String campaignCode);
    Optional<InventoryLocation> findBySkuAndWarehouseBin(String sku, String warehouseBin);

    @Query("SELECT SUM(i.quantityAvailable) FROM InventoryLocation i WHERE i.sku = :sku")
    Integer sumAvailableQuantityBySku(String sku);

    @Query("SELECT SUM(i.quantityOnHand) FROM InventoryLocation i WHERE i.campaignCode = :campaignCode")
    Integer sumOnHandByCampaignCode(String campaignCode);
}
