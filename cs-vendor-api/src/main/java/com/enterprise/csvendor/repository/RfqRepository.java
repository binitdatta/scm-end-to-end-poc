package com.enterprise.csvendor.repository;

import com.enterprise.csvendor.entity.Rfq;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface RfqRepository extends JpaRepository<Rfq, Long> {
    Optional<Rfq> findByExternalId(String externalId);
    Optional<Rfq> findByRfqNumber(String rfqNumber);
    boolean existsByRfqNumber(String rfqNumber);
    List<Rfq> findByStatus(Rfq.Status status);
    List<Rfq> findByCampaignExternalId(String campaignExternalId);
}
