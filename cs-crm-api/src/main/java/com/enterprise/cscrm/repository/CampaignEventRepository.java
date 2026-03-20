package com.enterprise.cscrm.repository;

import com.enterprise.cscrm.entity.CampaignEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CampaignEventRepository extends JpaRepository<CampaignEvent, Long> {
    List<CampaignEvent> findByCampaignIdOrderByEventAtDesc(Long campaignId);
}
