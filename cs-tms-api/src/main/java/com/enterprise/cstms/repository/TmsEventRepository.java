package com.enterprise.cstms.repository;

import com.enterprise.cstms.entity.TmsEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TmsEventRepository extends JpaRepository<TmsEvent, Long> {
    List<TmsEvent> findByDeliveryLoadIdOrderByEventAtDesc(Long deliveryLoadId);
}
