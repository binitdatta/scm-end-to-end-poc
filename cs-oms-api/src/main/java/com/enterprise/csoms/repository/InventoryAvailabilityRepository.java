package com.enterprise.csoms.repository;

import com.enterprise.csoms.entity.InventoryAvailability;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface InventoryAvailabilityRepository extends JpaRepository<InventoryAvailability, Long> {
    Optional<InventoryAvailability> findBySkuAndCampaignCode(String sku, String campaignCode);
    List<InventoryAvailability> findByCampaignCode(String campaignCode);
}
