package com.enterprise.cscrm.repository;

import com.enterprise.cscrm.entity.Campaign;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface CampaignRepository extends JpaRepository<Campaign, Long> {
    Optional<Campaign> findByExternalId(String externalId);
    Optional<Campaign> findByCampaignCode(String campaignCode);
    boolean existsByCampaignCode(String campaignCode);
}
