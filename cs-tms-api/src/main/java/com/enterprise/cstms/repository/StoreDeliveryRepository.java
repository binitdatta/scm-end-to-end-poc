package com.enterprise.cstms.repository;

import com.enterprise.cstms.entity.StoreDelivery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface StoreDeliveryRepository extends JpaRepository<StoreDelivery, Long> {
    List<StoreDelivery> findByDeliveryLoadId(Long deliveryLoadId);
    Optional<StoreDelivery> findByExternalId(String externalId);
    List<StoreDelivery> findByDeliveryLoadIdAndStatus(Long loadId, StoreDelivery.Status status);
}
