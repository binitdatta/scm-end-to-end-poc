package com.enterprise.cswmsinbound.repository;

import com.enterprise.cswmsinbound.entity.ReceivingRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface ReceivingRecordRepository extends JpaRepository<ReceivingRecord, Long> {
    Optional<ReceivingRecord> findByExternalId(String externalId);
    Optional<ReceivingRecord> findByAsnId(Long asnId);
    boolean existsByAsnId(Long asnId);
}
