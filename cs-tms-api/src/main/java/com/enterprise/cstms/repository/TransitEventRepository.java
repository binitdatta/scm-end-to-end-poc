package com.enterprise.cstms.repository;

import com.enterprise.cstms.entity.TransitEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TransitEventRepository extends JpaRepository<TransitEvent, Long> {
    List<TransitEvent> findByDeliveryLoadIdOrderByEventAtDesc(Long deliveryLoadId);
}
