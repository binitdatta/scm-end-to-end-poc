package com.enterprise.cswmsoutbound.repository;

import com.enterprise.cswmsoutbound.entity.OutboundShipment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface OutboundShipmentRepository extends JpaRepository<OutboundShipment, Long> {
    Optional<OutboundShipment> findByExternalId(String externalId);
    Optional<OutboundShipment> findByShipmentNumber(String shipmentNumber);
    boolean existsByShipmentNumber(String shipmentNumber);
    List<OutboundShipment> findByStatus(OutboundShipment.Status status);
    List<OutboundShipment> findByCampaignCode(String campaignCode);
    Optional<OutboundShipment> findByStoreOrderExternalId(String storeOrderExternalId);
}
