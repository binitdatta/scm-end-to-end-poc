package com.enterprise.cstms.repository;

import com.enterprise.cstms.entity.DeliveryLoad;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryLoadRepository extends JpaRepository<DeliveryLoad, Long> {
    Optional<DeliveryLoad> findByExternalId(String externalId);
    Optional<DeliveryLoad> findByLoadNumber(String loadNumber);
    Optional<DeliveryLoad> findByShipmentExternalId(String shipmentExternalId);
    boolean existsByShipmentExternalId(String shipmentExternalId);
    boolean existsByLoadNumber(String loadNumber);
    List<DeliveryLoad> findByStatus(DeliveryLoad.Status status);
    List<DeliveryLoad> findByCampaignCode(String campaignCode);
    List<DeliveryLoad> findByCarrierName(String carrierName);
}
