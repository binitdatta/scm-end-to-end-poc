package com.enterprise.cswmsinbound.repository;

import com.enterprise.cswmsinbound.entity.AdvanceShipmentNotice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface AsnRepository extends JpaRepository<AdvanceShipmentNotice, Long> {
    Optional<AdvanceShipmentNotice> findByExternalId(String externalId);
    Optional<AdvanceShipmentNotice> findByAsnNumber(String asnNumber);
    Optional<AdvanceShipmentNotice> findByPoExternalId(String poExternalId);
    boolean existsByPoExternalId(String poExternalId);
    boolean existsByAsnNumber(String asnNumber);
    List<AdvanceShipmentNotice> findByStatus(AdvanceShipmentNotice.Status status);
    List<AdvanceShipmentNotice> findByCampaignCode(String campaignCode);
}
