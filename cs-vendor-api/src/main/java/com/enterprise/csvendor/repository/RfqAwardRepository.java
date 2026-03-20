package com.enterprise.csvendor.repository;

import com.enterprise.csvendor.entity.RfqAward;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface RfqAwardRepository extends JpaRepository<RfqAward, Long> {
    Optional<RfqAward> findByExternalId(String externalId);
    Optional<RfqAward> findByRfqId(Long rfqId);
    boolean existsByRfqId(Long rfqId);
}
