package com.enterprise.csoms.repository;

import com.enterprise.csoms.entity.StoreRegion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface StoreRegionRepository extends JpaRepository<StoreRegion, Long> {
    Optional<StoreRegion> findByExternalId(String externalId);
    Optional<StoreRegion> findByRegionCode(String regionCode);
    List<StoreRegion> findByStatus(StoreRegion.Status status);
}
