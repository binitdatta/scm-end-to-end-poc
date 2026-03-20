package com.enterprise.csprocurement.repository;

import com.enterprise.csprocurement.entity.PurchaseOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PurchaseOrderRepository extends JpaRepository<PurchaseOrder, Long> {
    Optional<PurchaseOrder> findByExternalId(String externalId);
    Optional<PurchaseOrder> findByPoNumber(String poNumber);
    Optional<PurchaseOrder> findByAwardExternalId(String awardExternalId);
    boolean existsByPoNumber(String poNumber);
    boolean existsByAwardExternalId(String awardExternalId);
    List<PurchaseOrder> findByStatus(PurchaseOrder.Status status);
    List<PurchaseOrder> findByCampaignExternalId(String campaignExternalId);
    List<PurchaseOrder> findByVendorExternalId(String vendorExternalId);
}
