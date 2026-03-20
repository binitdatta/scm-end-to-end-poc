package com.enterprise.csoms.repository;

import com.enterprise.csoms.entity.Store;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface StoreRepository extends JpaRepository<Store, Long> {
    Optional<Store> findByExternalId(String externalId);
    Optional<Store> findByStoreNumber(String storeNumber);
    List<Store> findByRegionId(Long regionId);
    List<Store> findByRegionIdAndStatus(Long regionId, Store.Status status);
}
