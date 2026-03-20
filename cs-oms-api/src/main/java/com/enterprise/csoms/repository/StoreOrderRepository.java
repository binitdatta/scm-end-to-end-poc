package com.enterprise.csoms.repository;

import com.enterprise.csoms.entity.StoreOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface StoreOrderRepository extends JpaRepository<StoreOrder, Long> {
    Optional<StoreOrder> findByExternalId(String externalId);
    Optional<StoreOrder> findByOrderNumber(String orderNumber);
    boolean existsByOrderNumber(String orderNumber);
    List<StoreOrder> findByStatus(StoreOrder.Status status);
    List<StoreOrder> findByCampaignCode(String campaignCode);
    List<StoreOrder> findByCampaignCodeAndSku(String campaignCode, String sku);
}
