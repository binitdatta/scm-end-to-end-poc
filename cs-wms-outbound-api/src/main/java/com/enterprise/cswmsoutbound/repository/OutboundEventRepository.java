package com.enterprise.cswmsoutbound.repository;

import com.enterprise.cswmsoutbound.entity.OutboundEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OutboundEventRepository extends JpaRepository<OutboundEvent, Long> {
    List<OutboundEvent> findByEntityTypeAndEntityIdOrderByEventAtDesc(String entityType, Long entityId);
}
